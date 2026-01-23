<script setup>
import AppHeader from '@/components/common/AppHeader.vue'
import { useRoute } from 'vue-router'

const route = useRoute()
const projectId = route.params.id
</script>

<template>
  <div class="min-h-screen bg-neutral-50">
    <AppHeader />

    <main class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
      <div class="text-center py-12">
        <h1 class="text-2xl font-bold text-neutral-900 mb-4">
          Project Detail View
        </h1>
        <p class="text-gray-600 mb-4">
          Project ID: {{ projectId }}
        </p>
        <p class="text-gray-600">
          This view will show project details and the production table.
        </p>
      </div>
    </main>
  </div>
</template>
