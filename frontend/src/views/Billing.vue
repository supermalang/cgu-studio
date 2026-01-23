<script setup>
import Sidebar from '@/components/common/Sidebar.vue'
import AppHeader from '@/components/common/AppHeader.vue'
</script>

<template>
  <div class="flex min-h-screen bg-neutral-50">
    <Sidebar />

    <div class="flex-1 ml-64">
      <AppHeader />

      <main class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        <!-- Page Header -->
        <div class="mb-8">
          <h1 class="text-3xl font-bold text-neutral-900">
            Billing
          </h1>
          <p class="text-gray-600 mt-2">
            Manage your subscription and payment methods
          </p>
        </div>

        <!-- Placeholder Content -->
        <div class="card p-12 text-center">
          <div class="max-w-md mx-auto">
            <svg class="w-24 h-24 mx-auto text-gray-300 mb-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 10h18M7 15h1m4 0h1m-7 4h12a3 3 0 003-3V8a3 3 0 00-3-3H6a3 3 0 00-3 3v8a3 3 0 003 3z" />
            </svg>
            <h2 class="text-2xl font-semibold text-neutral-900 mb-3">
              Billing Page Coming Soon
            </h2>
            <p class="text-gray-600 mb-6">
              This page will allow you to manage your subscription, view invoices, and update payment methods.
            </p>
            <div class="inline-flex items-center gap-2 px-4 py-2 bg-primary-50 text-primary-700 rounded-lg text-sm font-medium">
              <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
              </svg>
              Under Development
            </div>
          </div>
        </div>
      </main>
    </div>
  </div>
</template>
