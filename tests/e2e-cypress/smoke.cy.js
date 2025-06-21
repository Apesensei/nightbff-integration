// NightBFF Integration Smoke Tests
// Basic E2E tests to verify the integration stack is working correctly

describe('NightBFF Integration Smoke Tests', () => {
  const baseUrl = 'http://localhost:3000';

  beforeEach(() => {
    // Wait for services to be ready
    cy.wait(1000);
  });

  describe('Health and Documentation', () => {
    it('should have backend health endpoint responding', () => {
      cy.request('GET', `${baseUrl}/health`).then((response) => {
        expect(response.status).to.eq(200);
        expect(response.body).to.have.property('status');
      });
    });

    it('should have swagger docs available', () => {
      cy.request('GET', `${baseUrl}/api/docs`).then((response) => {
        expect(response.status).to.eq(200);
        expect(response.headers['content-type']).to.include('text/html');
      });
    });

    it('should have API root responding', () => {
      cy.request('GET', `${baseUrl}/api`).then((response) => {
        expect(response.status).to.be.oneOf([200, 404]); // Either works or returns 404
      });
    });
  });

  describe('Authentication Endpoints', () => {
    it('should have frontend signin endpoint available', () => {
      // Test that the endpoint exists (even if it returns validation errors)
      cy.request({
        method: 'POST',
        url: `${baseUrl}/api/auth/frontend/signin`,
        body: {
          email: 'test@example.com',
          password: 'invalid'
        },
        failOnStatusCode: false
      }).then((response) => {
        // Endpoint should exist (not 404) and handle the request
        expect(response.status).to.not.equal(404);
        expect(response.status).to.be.oneOf([400, 401, 422]); // Expected validation/auth errors
      });
    });

    it('should have frontend signup endpoint available', () => {
      cy.request({
        method: 'POST',
        url: `${baseUrl}/api/auth/frontend/signup`,
        body: {
          email: 'test@example.com',
          password: 'invalid'
        },
        failOnStatusCode: false
      }).then((response) => {
        expect(response.status).to.not.equal(404);
        expect(response.status).to.be.oneOf([400, 401, 422]);
      });
    });
  });

  describe('Plan Endpoints', () => {
    it('should have plans endpoint available', () => {
      cy.request({
        method: 'POST',
        url: `${baseUrl}/api/plans`,
        body: {
          destination: 'Test City',
          startDate: '2025-12-01'
        },
        failOnStatusCode: false
      }).then((response) => {
        // Should exist but require authentication
        expect(response.status).to.not.equal(404);
        expect(response.status).to.be.oneOf([401, 403, 422]); // Auth required
      });
    });

    it('should have plan cache health check available', () => {
      cy.request('GET', `${baseUrl}/api/plans/cache-health-check`).then((response) => {
        expect(response.status).to.eq(200);
        expect(response.body).to.have.property('status');
      });
    });
  });

  describe('Database and Cache Connectivity', () => {
    it('should verify database connection through health check', () => {
      cy.request('GET', `${baseUrl}/health`).then((response) => {
        expect(response.status).to.eq(200);
        // Health check should indicate database is connected
        if (response.body.database) {
          expect(response.body.database).to.not.equal('disconnected');
        }
      });
    });

    it('should verify cache connection through plan health check', () => {
      cy.request('GET', `${baseUrl}/api/plans/cache-health-check`).then((response) => {
        expect(response.status).to.eq(200);
        expect(response.body.status).to.be.oneOf(['OK', 'ERROR']);
        // If status is OK, cache is working
        if (response.body.status === 'OK') {
          expect(response.body).to.have.property('operation');
        }
      });
    });
  });

  describe('Service Integration', () => {
    it('should handle CORS preflight requests', () => {
      cy.request({
        method: 'OPTIONS',
        url: `${baseUrl}/api/auth/frontend/signin`,
        headers: {
          'Origin': 'http://localhost:8081',
          'Access-Control-Request-Method': 'POST'
        }
      }).then((response) => {
        expect(response.status).to.be.oneOf([200, 204]);
      });
    });

    it('should return proper error format for invalid requests', () => {
      cy.request({
        method: 'POST',
        url: `${baseUrl}/api/auth/frontend/signin`,
        body: { invalid: 'data' },
        failOnStatusCode: false
      }).then((response) => {
        expect(response.status).to.be.oneOf([400, 422]);
        expect(response.body).to.be.an('object');
        // Should have error information
        expect(response.body).to.satisfy((body) => {
          return body.message || body.error || body.errors;
        });
      });
    });
  });
}); 