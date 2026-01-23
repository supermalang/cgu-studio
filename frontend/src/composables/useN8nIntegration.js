import { ref } from 'vue'

export function useN8nIntegration() {
  const isTesting = ref({
    avatars: false,
    environments: false,
    projects: false,
    all: false
  })

  const testResults = ref({
    avatars: null,
    environments: null,
    projects: null
  })

  async function testEndpoint(endpointName, url, apiToken) {
    if (!url || !apiToken) {
      return {
        success: false,
        error: 'URL and API token are required',
        status: 'failed'
      }
    }

    isTesting.value[endpointName] = true
    const startTime = performance.now()

    try {
      const response = await fetch(url, {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${apiToken}`,
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({
          test: true,
          timestamp: new Date().toISOString()
        }),
        signal: AbortSignal.timeout(10000) // 10 second timeout
      })

      const responseTime = Math.round(performance.now() - startTime)

      const result = {
        success: response.ok,
        status: response.ok ? 'connected' : 'failed',
        response_time_ms: responseTime,
        error: !response.ok ? `HTTP ${response.status}: ${response.statusText}` : null,
        tested_at: new Date().toISOString()
      }

      testResults.value[endpointName] = result
      return result

    } catch (error) {
      const responseTime = Math.round(performance.now() - startTime)
      let errorMessage = error.message

      if (error.name === 'AbortError' || error.name === 'TimeoutError') {
        errorMessage = 'Connection timeout (10s)'
      } else if (error.message.includes('Failed to fetch')) {
        errorMessage = 'Connection failed - Check URL and CORS settings'
      }

      const result = {
        success: false,
        status: 'failed',
        response_time_ms: responseTime,
        error: errorMessage,
        tested_at: new Date().toISOString()
      }

      testResults.value[endpointName] = result
      return result

    } finally {
      isTesting.value[endpointName] = false
    }
  }

  async function testAllEndpoints(endpoints, apiToken) {
    isTesting.value.all = true

    try {
      const results = await Promise.allSettled([
        testEndpoint('avatars', endpoints.avatars.url, apiToken),
        testEndpoint('environments', endpoints.environments.url, apiToken),
        testEndpoint('projects', endpoints.projects.url, apiToken)
      ])

      return results
    } finally {
      isTesting.value.all = false
    }
  }

  function validateUrl(url) {
    if (!url) return true // Optional field
    try {
      const parsed = new URL(url)
      return parsed.protocol === 'http:' || parsed.protocol === 'https:'
    } catch {
      return false
    }
  }

  return {
    isTesting,
    testResults,
    testEndpoint,
    testAllEndpoints,
    validateUrl
  }
}
