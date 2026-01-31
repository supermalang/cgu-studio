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

  async function sendToEndpoint(endpointUrl, apiToken, data) {
    console.log('[sendToEndpoint] Called with:', {
      url: endpointUrl,
      hasToken: !!apiToken,
      dataKeys: Object.keys(data || {})
    })

    if (!endpointUrl || !apiToken) {
      console.error('[sendToEndpoint] Missing required parameters')
      return {
        success: false,
        error: 'Endpoint URL and API token are required'
      }
    }

    try {
      console.log('[sendToEndpoint] Sending POST request...', {
        url: endpointUrl,
        payload: data
      })

      const response = await fetch(endpointUrl, {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${apiToken}`,
          'Content-Type': 'application/json'
        },
        body: JSON.stringify(data),
        signal: AbortSignal.timeout(15000) // 15 second timeout
      })

      console.log('[sendToEndpoint] Response received:', {
        status: response.status,
        ok: response.ok,
        statusText: response.statusText
      })

      const result = {
        success: response.ok,
        status: response.status,
        error: !response.ok ? `HTTP ${response.status}: ${response.statusText}` : null
      }

      // Try to parse response body if available
      try {
        const responseData = await response.json()
        result.data = responseData
        console.log('[sendToEndpoint] Response data:', responseData)
      } catch {
        // Response might not be JSON, that's okay
        console.log('[sendToEndpoint] Response is not JSON')
      }

      return result

    } catch (error) {
      console.error('[sendToEndpoint] Error:', error)
      let errorMessage = error.message

      if (error.name === 'AbortError' || error.name === 'TimeoutError') {
        errorMessage = 'Request timeout (15s)'
      } else if (error.message.includes('Failed to fetch')) {
        errorMessage = 'Connection failed - Check URL and CORS settings'
      }

      return {
        success: false,
        error: errorMessage
      }
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
    sendToEndpoint,
    validateUrl
  }
}
