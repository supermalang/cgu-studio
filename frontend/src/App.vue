<script setup>
import { onMounted } from 'vue'
import { useAuthStore } from '@/stores/auth'
import { useCompanyStore } from '@/stores/company'
import ToastContainer from '@/components/common/ToastContainer.vue'

const authStore = useAuthStore()
const companyStore = useCompanyStore()

onMounted(() => {
  authStore.initialize()
  companyStore.initialize()
})
</script>

<template>
  <div id="app">
    <RouterView />
    <ToastContainer />
  </div>
</template>

<style>
/* Any global styles can go here */
</style>
