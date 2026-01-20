<script setup>
import { onMounted } from 'vue'
import { useAuthStore } from '@/stores/auth'

const authStore = useAuthStore()

onMounted(() => {
  authStore.initialize()
})
</script>

<template>
  <div id="app">
    <RouterView />
  </div>
</template>

<style>
/* Any global styles can go here */
</style>
