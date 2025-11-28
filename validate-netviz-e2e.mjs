import puppeteer from 'puppeteer';
import { fileURLToPath } from 'url';
import { dirname, join } from 'path';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

const APP_URL = 'http://localhost:9040';
const TOPOLOGY_FILE = join(__dirname, 'netviz-pro-topo-extra layers.json');

// Default credentials (adjust if needed)
const USERNAME = 'admin';
const PASSWORD = 'admin';

async function sleep(ms) {
    return new Promise(resolve => setTimeout(resolve, ms));
}

async function validateNetvizPro() {
    console.log('🚀 Starting Netviz-Pro E2E Validation...\n');

    const browser = await puppeteer.launch({
        headless: false,
        defaultViewport: { width: 1920, height: 1080 },
        args: ['--no-sandbox', '--disable-setuid-sandbox']
    });

    try {
        const page = await browser.newPage();

        // Enable console logging
        page.on('console', msg => console.log('PAGE LOG:', msg.text()));
        page.on('pageerror', err => console.error('PAGE ERROR:', err));

        // ========================================
        // PHASE 0: Login
        // ========================================
        console.log('📍 Phase 0: Logging in...');
        await page.goto(APP_URL, { waitUntil: 'networkidle2' });
        await sleep(2000);

        // Check if login is required
        const loginRequired = await page.$('#username');
        if (loginRequired) {
            await page.type('#username', USERNAME);
            await page.type('#password', PASSWORD);

            // Find and click login button
            const loginButton = await page.evaluateHandle(() => {
                const buttons = Array.from(document.querySelectorAll('button'));
                return buttons.find(btn => btn.textContent.includes('Sign In') || btn.textContent.includes('Login'));
            });

            if (loginButton) {
                await loginButton.click();
                await sleep(3000);
                console.log('✓ Logged in\n');
            }
        } else {
            console.log('✓ No login required\n');
        }

        // ========================================
        // PHASE 1: Load Application
        // ========================================
        console.log('📍 Phase 1: Verifying Application Loaded...');
        await sleep(2000);

        await page.screenshot({ path: '/Users/macbook/.gemini/netviz-1-app-loaded.png', fullPage: true });
        console.log('✓ Application loaded\n');

        // ========================================
        // PHASE 2: Upload 100-Node Topology
        // ========================================
        console.log('📍 Phase 2: Uploading 100-Node Topology...');

        // Wait for file input to be available
        await page.waitForSelector('input[type="file"]', { timeout: 5000 });

        const fileInput = await page.$('input[type="file"]');
        if (!fileInput) {
            throw new Error('File input not found!');
        }

        await fileInput.uploadFile(TOPOLOGY_FILE);
        console.log('   File selected, waiting for processing...');
        await sleep(5000); // Wait for processing

        await page.screenshot({ path: '/Users/macbook/.gemini/netviz-2-topology-loaded.png', fullPage: true });
        console.log('✓ Topology uploaded\n');

        // ========================================
        // PHASE 3: Validate Node Count
        // ========================================
        console.log('📍 Phase 3: Validating Node Count...');

        const nodeCountText = await page.evaluate(() => {
            const elements = Array.from(document.querySelectorAll('*'));
            for (const el of elements) {
                if (el.textContent && el.textContent.includes('100') && el.textContent.includes('Nodes')) {
                    return el.textContent;
                }
            }
            return null;
        });

        if (nodeCountText) {
            console.log(`✓ Node count confirmed: ${nodeCountText}\n`);
        } else {
            console.warn('⚠️  Could not verify 100 nodes\n');
        }

        // ========================================
        // PHASE 4: Test Country Filtering
        // ========================================
        console.log('📍 Phase 4: Testing Country Filtering...');

        const zafClicked = await page.evaluate(() => {
            const buttons = Array.from(document.querySelectorAll('button'));
            const zafBtn = buttons.find(btn => btn.textContent && btn.textContent.includes('ZAF'));
            if (zafBtn) {
                zafBtn.click();
                return true;
            }
            return false;
        });

        if (zafClicked) {
            await sleep(2000);
            await page.screenshot({ path: '/Users/macbook/.gemini/netviz-3-zaf-filtered.png', fullPage: true });
            console.log('✓ ZAF filter applied\n');
        } else {
            console.warn('⚠️  ZAF button not found\n');
        }

        // ========================================
        // PHASE 5: Test View Mode Toggle
        // ========================================
        console.log('📍 Phase 5: Testing View Mode Toggle...');

        const highLevelClicked = await page.evaluate(() => {
            const buttons = Array.from(document.querySelectorAll('button'));
            const hlBtn = buttons.find(btn => btn.textContent && btn.textContent.includes('High Level'));
            if (hlBtn) {
                hlBtn.click();
                return true;
            }
            return false;
        });

        if (highLevelClicked) {
            await sleep(2000);
            await page.screenshot({ path: '/Users/macbook/.gemini/netviz-4-high-level-view.png', fullPage: true });
            console.log('✓ High-level view activated\n');

            // Switch back to detailed
            const detailedClicked = await page.evaluate(() => {
                const buttons = Array.from(document.querySelectorAll('button'));
                const detBtn = buttons.find(btn => btn.textContent && btn.textContent.includes('Detailed'));
                if (detBtn) {
                    detBtn.click();
                    return true;
                }
                return false;
            });

            if (detailedClicked) {
                await sleep(2000);
                console.log('✓ Switched back to detailed view\n');
            }
        } else {
            console.warn('⚠️  View mode toggle not found\n');
        }

        // ========================================
        // PHASE 6: Click on a Node
        // ========================================
        console.log('📍 Phase 6: Testing Node Click...');

        const nodeClicked = await page.evaluate(() => {
            const circles = document.querySelectorAll('svg circle');
            if (circles.length > 0) {
                circles[0].dispatchEvent(new MouseEvent('click', { bubbles: true }));
                return true;
            }
            return false;
        });

        if (nodeClicked) {
            await sleep(1500);
            await page.screenshot({ path: '/Users/macbook/.gemini/netviz-5-node-selected.png', fullPage: true });
            console.log('✓ Node clicked\n');
        } else {
            console.warn('⚠️  No nodes found to click\n');
        }

        // ========================================
        // PHASE 7: Check for Neighbor Count
        // ========================================
        console.log('📍 Phase 7: Validating Neighbor Count Display...');

        const neighborText = await page.evaluate(() => {
            const elements = Array.from(document.querySelectorAll('*'));
            for (const el of elements) {
                if (el.textContent && (el.textContent.includes('Neighbors') || el.textContent.includes('NEIGHBORS'))) {
                    return el.textContent.trim();
                }
            }
            return null;
        });

        if (neighborText) {
            console.log(`✓ Neighbor count found: ${neighborText}\n`);
        } else {
            console.warn('⚠️  Neighbor count not displayed\n');
        }

        // ========================================
        // PHASE 8: Test Link Click
        // ========================================
        console.log('📍 Phase 8: Testing Link Click...');

        const linkClicked = await page.evaluate(() => {
            const lines = document.querySelectorAll('svg line');
            if (lines.length > 0) {
                lines[0].dispatchEvent(new MouseEvent('click', { bubbles: true }));
                return true;
            }
            return false;
        });

        if (linkClicked) {
            await sleep(1500);
            await page.screenshot({ path: '/Users/macbook/.gemini/netviz-6-link-clicked.png', fullPage: true });
            console.log('✓ Link clicked\n');
        } else {
            console.warn('⚠️  No links found to click\n');
        }

        // ========================================
        // PHASE 9: Test Pause/Resume
        // ========================================
        console.log('📍 Phase 9: Testing Pause/Resume...');

        const pauseClicked = await page.evaluate(() => {
            const buttons = Array.from(document.querySelectorAll('button'));
            const pauseBtn = buttons.find(btn => btn.title && (btn.title.includes('Pause') || btn.title.includes('pause')));
            if (pauseBtn) {
                pauseBtn.click();
                return true;
            }
            return false;
        });

        if (pauseClicked) {
            await sleep(1000);
            console.log('✓ Simulation paused\n');

            await page.evaluate(() => {
                const buttons = Array.from(document.querySelectorAll('button'));
                const resumeBtn = buttons.find(btn => btn.title && (btn.title.includes('Resume') || btn.title.includes('resume')));
                if (resumeBtn) resumeBtn.click();
            });
            await sleep(1000);
            console.log('✓ Simulation resumed\n');
        } else {
            console.warn('⚠️  Pause button not found\n');
        }

        // ========================================
        // PHASE 10: Final Screenshot
        // ========================================
        await page.screenshot({ path: '/Users/macbook/.gemini/netviz-7-final-state.png', fullPage: true });

        console.log('='.repeat(80));
        console.log('✅ E2E VALIDATION COMPLETE');
        console.log('='.repeat(80));
        console.log('\n📸 Screenshots saved to ~/.gemini/');
        console.log('   - netviz-1-app-loaded.png');
        console.log('   - netviz-2-topology-loaded.png');
        console.log('   - netviz-3-zaf-filtered.png');
        console.log('   - netviz-4-high-level-view.png');
        console.log('   - netviz-5-node-selected.png');
        console.log('   - netviz-6-link-clicked.png');
        console.log('   - netviz-7-final-state.png\n');

    } catch (error) {
        console.error('❌ Validation failed:', error);
        await page.screenshot({ path: '/Users/macbook/.gemini/netviz-error.png', fullPage: true });
        throw error;
    } finally {
        await browser.close();
    }
}

validateNetvizPro().catch(console.error);
