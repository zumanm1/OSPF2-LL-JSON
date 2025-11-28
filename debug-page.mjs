import puppeteer from 'puppeteer';

const APP_URL = 'http://localhost:9040';

async function debugPage() {
    const browser = await puppeteer.launch({
        headless: false,
        defaultViewport: { width: 1920, height: 1080 }
    });

    const page = await browser.newPage();
    await page.goto(APP_URL, { waitUntil: 'networkidle2' });
    await new Promise(resolve => setTimeout(resolve, 3000));

    // Find all input elements
    const inputs = await page.evaluate(() => {
        const allInputs = Array.from(document.querySelectorAll('input'));
        return allInputs.map(input => ({
            type: input.type,
            accept: input.accept,
            className: input.className,
            id: input.id,
            name: input.name
        }));
    });

    console.log('Found inputs:', JSON.stringify(inputs, null, 2));

    // Try to find file input by clicking the upload area
    const uploadClicked = await page.evaluate(() => {
        const uploadDivs = Array.from(document.querySelectorAll('div'));
        for (const div of uploadDivs) {
            if (div.textContent && div.textContent.includes('Click to upload')) {
                console.log('Found upload div');
                return true;
            }
        }
        return false;
    });

    console.log('Upload div found:', uploadClicked);

    await new Promise(resolve => setTimeout(resolve, 60000)); // Keep open for inspection
    await browser.close();
}

debugPage().catch(console.error);
