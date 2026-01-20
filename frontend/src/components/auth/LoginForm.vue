<script setup>
import { ref } from 'vue'
import { useRouter } from 'vue-router'
import { useAuthStore } from '@/stores/auth'

const router = useRouter()
const authStore = useAuthStore()

const email = ref('')
const password = ref('')
const isLoading = ref(false)
const error = ref(null)

async function handleLogin() {
  if (!email.value || !password.value) {
    error.value = 'Please fill in all fields'
    return
  }

  isLoading.value = true
  error.value = null

  try {
    const { error: loginError } = await authStore.signIn(email.value, password.value)

    if (loginError) {
      error.value = loginError.message
      return
    }

    // Redirect to dashboard on success
    router.push('/dashboard')
  } catch (err) {
    error.value = 'An unexpected error occurred'
    console.error('Login error:', err)
  } finally {
    isLoading.value = false
  }
}

async function handleGoogleLogin() {
  isLoading.value = true
  error.value = null

  try {
    const { error: loginError } = await authStore.signInWithGoogle()

    if (loginError) {
      error.value = loginError.message
    }
  } catch (err) {
    error.value = 'An unexpected error occurred'
    console.error('Google login error:', err)
  } finally {
    isLoading.value = false
  }
}
</script>

<template>
  <div class="w-full max-w-md">
    <div class="card">
      <h1 class="text-2xl font-bold text-neutral-900 mb-6">Log in to UCG Studio</h1>

      <!-- Error Message -->
      <div v-if="error" class="bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded-lg mb-4">
        {{ error }}
      </div>

      <!-- Login Form -->
      <form @submit.prevent="handleLogin" class="space-y-4">
        <div>
          <label for="email" class="block text-sm font-medium text-neutral-900 mb-1">
            Email
          </label>
          <input
            id="email"
            v-model="email"
            type="email"
            required
            class="input-field"
            placeholder="you@example.com"
            :disabled="isLoading"
          />
        </div>

        <div>
          <label for="password" class="block text-sm font-medium text-neutral-900 mb-1">
            Password
          </label>
          <input
            id="password"
            v-model="password"
            type="password"
            required
            class="input-field"
            placeholder="••••••••"
            :disabled="isLoading"
          />
        </div>

        <div class="flex items-center justify-between">
          <div class="flex items-center">
            <input
              id="remember"
              type="checkbox"
              class="h-4 w-4 text-primary focus:ring-primary border-gray-300 rounded"
            />
            <label for="remember" class="ml-2 block text-sm text-neutral-900">
              Remember me
            </label>
          </div>

          <router-link
            to="/auth/reset-password"
            class="text-sm text-primary hover:underline"
          >
            Forgot password?
          </router-link>
        </div>

        <button
          type="submit"
          :disabled="isLoading"
          class="btn-primary w-full"
        >
          {{ isLoading ? 'Logging in...' : 'Log in' }}
        </button>
      </form>

      <!-- Divider -->
      <div class="relative my-6">
        <div class="absolute inset-0 flex items-center">
          <div class="w-full border-t border-gray-300"></div>
        </div>
        <div class="relative flex justify-center text-sm">
          <span class="px-2 bg-white text-gray-500">Or continue with</span>
        </div>
      </div>

      <!-- Google Login -->
      <button
        @click="handleGoogleLogin"
        :disabled="isLoading"
        class="w-full flex items-center justify-center gap-3 px-4 py-2 border border-gray-300 rounded-lg text-neutral-900 font-medium hover:bg-gray-50 transition-colors disabled:opacity-50"
      >
        <svg class="w-5 h-5" viewBox="0 0 24 24">
          <path
            fill="#4285F4"
            d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z"
          />
          <path
            fill="#34A853"
            d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z"
          />
          <path
            fill="#FBBC05"
            d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.07H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.93l2.85-2.22.81-.62z"
          />
          <path
            fill="#EA4335"
            d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.07l3.66 2.84c.87-2.6 3.3-4.53 6.16-4.53z"
          />
        </svg>
        Google
      </button>

      <!-- Signup Link -->
      <p class="mt-6 text-center text-sm text-gray-600">
        Don't have an account?
        <router-link to="/auth/signup" class="text-primary hover:underline font-medium">
          Sign up
        </router-link>
      </p>
    </div>
  </div>
</template>
