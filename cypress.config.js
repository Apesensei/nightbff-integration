const { defineConfig } = require('cypress');

module.exports = defineConfig({
  e2e: {
    // Base configuration for integration tests
    baseUrl: 'http://localhost:3000',
    supportFile: false, // Disable support file for simple smoke tests
    
    // Test file patterns
    specPattern: 'tests/e2e-cypress/**/*.cy.{js,jsx,ts,tsx}',
    
    // Viewport settings
    viewportWidth: 1280,
    viewportHeight: 720,
    
    // Timeouts
    defaultCommandTimeout: 10000,
    requestTimeout: 15000,
    responseTimeout: 15000,
    pageLoadTimeout: 30000,
    
    // Video and screenshot settings
    video: true,
    videoCompression: 32,
    screenshotOnRunFailure: true,
    screenshotsFolder: 'cypress/screenshots',
    videosFolder: 'cypress/videos',
    
    // Test settings
    watchForFileChanges: false,
    chromeWebSecurity: false, // Allow cross-origin requests for API testing
    
    // Retry settings for CI stability
    retries: {
      runMode: 2, // Retry failed tests twice in CI
      openMode: 0, // No retries in interactive mode
    },
    
    // Environment variables
    env: {
      // API base URL for tests
      apiUrl: 'http://localhost:3000/api',
      
      // Test timeouts
      healthCheckTimeout: 30000,
      serviceStartupTimeout: 120000,
      
      // Test data
      testEmail: 'integration-test@nightbff.com',
      testPassword: 'integration-test-password',
    },
    
    setupNodeEvents(on, config) {
      // Custom tasks for integration testing
      on('task', {
        // Task to wait for service health
        waitForHealth(url) {
          return new Promise((resolve, reject) => {
            const maxAttempts = 30;
            let attempts = 0;
            
            const checkHealth = () => {
              attempts++;
              
              require('http').get(url, (res) => {
                if (res.statusCode === 200) {
                  console.log(`✅ Service healthy at ${url} after ${attempts} attempts`);
                  resolve(true);
                } else if (attempts >= maxAttempts) {
                  reject(new Error(`Service not healthy after ${maxAttempts} attempts`));
                } else {
                  setTimeout(checkHealth, 2000);
                }
              }).on('error', (err) => {
                if (attempts >= maxAttempts) {
                  reject(new Error(`Service not reachable: ${err.message}`));
                } else {
                  setTimeout(checkHealth, 2000);
                }
              });
            };
            
            checkHealth();
          });
        },
        
        // Task to log messages from tests
        log(message) {
          console.log(`[Cypress Task] ${message}`);
          return null;
        },
      });
      
      // Browser launch options for CI
      on('before:browser:launch', (browser = {}, launchOptions) => {
        if (browser.name === 'chrome') {
          launchOptions.args.push('--disable-dev-shm-usage');
          launchOptions.args.push('--no-sandbox');
          launchOptions.args.push('--disable-gpu');
          launchOptions.args.push('--disable-web-security');
          launchOptions.args.push('--allow-running-insecure-content');
        }
        
        return launchOptions;
      });
      
      return config;
    },
  },
  
  // Component testing configuration (future use)
  component: {
    devServer: {
      framework: 'react',
      bundler: 'webpack',
    },
    specPattern: 'tests/component/**/*.cy.{js,jsx,ts,tsx}',
  },
}); 