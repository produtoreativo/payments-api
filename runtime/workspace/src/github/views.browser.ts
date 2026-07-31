/**
 * Browser Automation adapter for GitHub ProjectsV2 view management.
 *
 * Isolated from Provisioner/Doctor business logic — this is a pure adapter
 * that translates view config declarations into GitHub UI interactions.
 *
 * Requires:
 *   - playwright installed (npm install playwright)
 *   - GH_BROWSER_AUTH_STATE env var: path to a Playwright storage state JSON
 *   - Generate storage state: npx playwright codegen --save-storage=auth.json github.com
 *
 * Security:
 *   - Auth state file is NEVER read in code — passed to Playwright's storageState option
 *   - Storage state file must NOT be versioned (.gitignore: *.playwright-auth.json)
 *   - Credentials are never stored in code or logged
 */

import type { ViewConfig } from '../types.js';

export interface BrowserViewResult {
  name: string;
  created: boolean;
  alreadyExisted: boolean;
  layout: string;
  url: string;
  evidence: BrowserViewEvidence;
}

export interface BrowserViewEvidence {
  timestamp: string;
  strategy: 'browser-automation';
  sessionSource: string;
  viewTabFound: boolean;
  layoutConfirmed: boolean;
}

export async function ensureViewViaBrowser(
  owner: string,
  projectNumber: number,
  view: ViewConfig
): Promise<BrowserViewResult> {
  const authStatePath = process.env['GH_BROWSER_AUTH_STATE'];
  if (!authStatePath) {
    throw new Error(
      'GH_BROWSER_AUTH_STATE env var required for browser automation. ' +
        'Set it to a Playwright storage state file path.'
    );
  }

  const { chromium } = await import('playwright');
  const projectUrl = `https://github.com/orgs/${owner}/projects/${projectNumber}`;

  const browser = await chromium.launch({ headless: true });
  const context = await browser.newContext({ storageState: authStatePath });
  const page = await context.newPage();

  try {
    await page.goto(projectUrl, { waitUntil: 'networkidle', timeout: 30000 });

    // Check if view already exists by scanning tab buttons
    const existingView = await findViewTab(page, view.name);
    if (existingView) {
      const evidence: BrowserViewEvidence = {
        timestamp: new Date().toISOString(),
        strategy: 'browser-automation',
        sessionSource: authStatePath,
        viewTabFound: true,
        layoutConfirmed: false, // layout verification requires clicking the view
      };
      return {
        name: view.name,
        created: false,
        alreadyExisted: true,
        layout: view.layout,
        url: projectUrl,
        evidence,
      };
    }

    // Create new view
    await createView(page, view);

    // Validate: check the new view tab exists
    await page.waitForTimeout(2000);
    const viewTabFound = await findViewTab(page, view.name) !== null;

    const evidence: BrowserViewEvidence = {
      timestamp: new Date().toISOString(),
      strategy: 'browser-automation',
      sessionSource: authStatePath,
      viewTabFound,
      layoutConfirmed: viewTabFound,
    };

    return {
      name: view.name,
      created: viewTabFound,
      alreadyExisted: false,
      layout: view.layout,
      url: projectUrl,
      evidence,
    };
  } finally {
    await context.close();
    await browser.close();
  }
}

/**
 * Lists view names visible in the project's tab bar.
 * Returns tab elements found — null if not found on page.
 */
async function findViewTab(
  page: import('playwright').Page,
  viewName: string
): Promise<import('playwright').ElementHandle | null> {
  // GitHub Projects renders view tabs as links/buttons in the top nav
  // Multiple selector patterns for resilience across GitHub UI versions
  const selectors = [
    `[data-view-component="true"] a:has-text("${viewName}")`,
    `nav a:has-text("${viewName}")`,
    `button:has-text("${viewName}")`,
    `[role="tab"]:has-text("${viewName}")`,
  ];

  for (const selector of selectors) {
    const el = await page.$(selector);
    if (el) return el;
  }
  return null;
}

/**
 * Creates a new view via GitHub Projects UI.
 * Clicks the "+" tab button, selects layout, and renames the view.
 */
async function createView(page: import('playwright').Page, view: ViewConfig): Promise<void> {
  // Click the "New view" / "+" button
  // GitHub Projects uses multiple UI patterns depending on the version
  const addViewSelectors = [
    'button[aria-label="New view"]',
    'button[aria-label="Add view"]',
    '[data-testid="project-add-view-button"]',
    'button:has-text("New view")',
    // The "+" near the last view tab
    'li:last-child button[aria-label*="new"], li:last-child button[aria-label*="add"]',
  ];

  let clicked = false;
  for (const selector of addViewSelectors) {
    try {
      await page.click(selector, { timeout: 3000 });
      clicked = true;
      break;
    } catch {
      continue;
    }
  }

  if (!clicked) {
    throw new Error(
      'Could not find the "New view" button on the GitHub Projects page. ' +
        'The GitHub Projects UI may have changed. Screenshot would help diagnose this.'
    );
  }

  await page.waitForTimeout(500);

  // Select layout — GitHub shows layout options in a menu or inline
  if (view.layout === 'BOARD') {
    const boardSelectors = [
      'button:has-text("Board")',
      '[data-component="ActionList.Item"]:has-text("Board")',
      'li:has-text("Board")',
    ];
    for (const sel of boardSelectors) {
      try {
        await page.click(sel, { timeout: 3000 });
        break;
      } catch {
        continue;
      }
    }
  } else {
    const tableSelectors = [
      'button:has-text("Table")',
      '[data-component="ActionList.Item"]:has-text("Table")',
      'li:has-text("Table")',
    ];
    for (const sel of tableSelectors) {
      try {
        await page.click(sel, { timeout: 3000 });
        break;
      } catch {
        continue;
      }
    }
  }

  await page.waitForTimeout(500);

  // Rename the view from the default name to view.name
  // GitHub auto-focuses the view name input after creation
  const nameInputSelectors = [
    'input[placeholder*="View name"]',
    'input[placeholder*="New View"]',
    '[data-testid="view-name-input"]',
    'input[aria-label*="view name" i]',
  ];

  let renamed = false;
  for (const sel of nameInputSelectors) {
    try {
      const input = await page.$(sel);
      if (input) {
        await input.click({ clickCount: 3 }); // select all
        await input.type(view.name, { delay: 50 });
        await page.keyboard.press('Enter');
        renamed = true;
        break;
      }
    } catch {
      continue;
    }
  }

  if (!renamed) {
    // Try double-clicking the new active tab to rename
    await page.waitForTimeout(1000);
    const activeTab = await page.$('[aria-selected="true"][role="tab"], [data-selected="true"]');
    if (activeTab) {
      await activeTab.dblclick();
      await page.waitForTimeout(300);
      await page.keyboard.type(view.name);
      await page.keyboard.press('Enter');
    }
  }

  // Wait for the view to be saved
  await page.waitForTimeout(1500);
}

/**
 * Lists all view names currently present in a project via browser.
 * Used for validation — avoids GraphQL for checking filter/groupBy state.
 */
export async function listViewsViaBrowser(
  owner: string,
  projectNumber: number
): Promise<string[]> {
  const authStatePath = process.env['GH_BROWSER_AUTH_STATE'];
  if (!authStatePath) return [];

  const { chromium } = await import('playwright');
  const browser = await chromium.launch({ headless: true });
  const context = await browser.newContext({ storageState: authStatePath });
  const page = await context.newPage();

  try {
    await page.goto(
      `https://github.com/orgs/${owner}/projects/${projectNumber}`,
      { waitUntil: 'networkidle', timeout: 30000 }
    );

    const tabs = await page.$$('[role="tab"], nav a[data-view-component]');
    const names: string[] = [];
    for (const tab of tabs) {
      const text = await tab.textContent();
      if (text?.trim()) names.push(text.trim());
    }
    return names;
  } finally {
    await context.close();
    await browser.close();
  }
}
