<script setup>
import { ref, watch } from 'vue'

const props = defineProps({
  settings: {
    type: Object,
    default: null
  }
})

const emit = defineEmits(['update'])

const packages = ref([])
const showModal = ref(false)
const editingIndex = ref(null)
const packageForm = ref({
  price_usd: '',
  price_eur: '',
  price_xof: '',
  credits: ''
})
const packageErrors = ref({
  price_usd: '',
  price_eur: '',
  price_xof: '',
  credits: ''
})

// Watch settings and populate packages
watch(() => props.settings, (newSettings) => {
  if (newSettings?.credit_packages) {
    packages.value = [...newSettings.credit_packages]
  }
}, { immediate: true, deep: true })

function openAddModal() {
  editingIndex.value = null
  packageForm.value = { price_usd: '', price_eur: '', price_xof: '', credits: '' }
  packageErrors.value = { price_usd: '', price_eur: '', price_xof: '', credits: '' }
  showModal.value = true
}

function openEditModal(index) {
  editingIndex.value = index
  const pkg = packages.value[index]
  packageForm.value = {
    price_usd: pkg.price_usd || '',
    price_eur: pkg.price_eur || '',
    price_xof: pkg.price_xof || '',
    credits: pkg.credits || ''
  }
  packageErrors.value = { price_usd: '', price_eur: '', price_xof: '', credits: '' }
  showModal.value = true
}

function closeModal() {
  showModal.value = false
  editingIndex.value = null
  packageForm.value = { price_usd: '', price_eur: '', price_xof: '', credits: '' }
  packageErrors.value = { price_usd: '', price_eur: '', price_xof: '', credits: '' }
}

function validatePackageForm() {
  let isValid = true
  packageErrors.value = { price_usd: '', price_eur: '', price_xof: '', credits: '' }

  // At least one price must be provided
  const hasAtLeastOnePrice = packageForm.value.price_usd > 0 ||
                              packageForm.value.price_eur > 0 ||
                              packageForm.value.price_xof > 0

  if (!hasAtLeastOnePrice) {
    packageErrors.value.price_usd = 'At least one price must be greater than 0'
    isValid = false
  }

  // Validate individual prices if provided
  if (packageForm.value.price_usd && packageForm.value.price_usd <= 0) {
    packageErrors.value.price_usd = 'USD price must be greater than 0'
    isValid = false
  }

  if (packageForm.value.price_eur && packageForm.value.price_eur <= 0) {
    packageErrors.value.price_eur = 'EUR price must be greater than 0'
    isValid = false
  }

  if (packageForm.value.price_xof && packageForm.value.price_xof <= 0) {
    packageErrors.value.price_xof = 'XOF price must be greater than 0'
    isValid = false
  }

  if (!packageForm.value.credits || packageForm.value.credits <= 0) {
    packageErrors.value.credits = 'Credits must be greater than 0'
    isValid = false
  }

  return isValid
}

function handleSavePackage() {
  if (!validatePackageForm()) return

  const newPackage = {
    price_usd: packageForm.value.price_usd ? Number(packageForm.value.price_usd) : null,
    price_eur: packageForm.value.price_eur ? Number(packageForm.value.price_eur) : null,
    price_xof: packageForm.value.price_xof ? Number(packageForm.value.price_xof) : null,
    credits: Number(packageForm.value.credits)
  }

  if (editingIndex.value !== null) {
    // Update existing package
    packages.value[editingIndex.value] = newPackage
  } else {
    // Add new package
    packages.value.push(newPackage)
  }

  // Sort by credits (descending)
  packages.value.sort((a, b) => b.credits - a.credits)

  // Emit update after mutation
  emit('update', [...packages.value])

  closeModal()
}

function handleDeletePackage(index) {
  if (confirm('Are you sure you want to delete this credit package?')) {
    packages.value.splice(index, 1)
    // Emit update after mutation
    emit('update', [...packages.value])
  }
}

function formatPrice(price, currency) {
  if (!price) return '-'

  const formattedNumber = new Intl.NumberFormat('en-US', {
    minimumFractionDigits: currency === 'XOF' ? 0 : 2,
    maximumFractionDigits: currency === 'XOF' ? 0 : 2
  }).format(price)

  // For XOF/FCFA, show symbol after the number
  if (currency === 'XOF') {
    return `${formattedNumber} FCFA`
  }

  const symbol = currency === 'EUR' ? '€' : '$'
  return `${symbol}${formattedNumber}`
}

function formatNumber(num) {
  return new Intl.NumberFormat('en-US').format(num)
}

function getPackagePrices(pkg) {
  const prices = []
  if (pkg.price_usd) prices.push(formatPrice(pkg.price_usd, 'USD'))
  if (pkg.price_eur) prices.push(formatPrice(pkg.price_eur, 'EUR'))
  if (pkg.price_xof) prices.push(formatPrice(pkg.price_xof, 'XOF'))
  return prices.join(' | ')
}
</script>

<template>
  <div class="card">
    <div class="px-6 py-4 border-b border-gray-200">
      <h3 class="text-lg font-semibold text-neutral-900">Credit Packages</h3>
      <p class="text-sm text-gray-600 mt-1">Manage pricing tiers for credit purchases</p>
    </div>

    <div class="p-6 space-y-4">
      <!-- Packages List -->
      <div class="space-y-3">
        <div
          v-for="(pkg, index) in packages"
          :key="index"
          class="flex items-center justify-between p-4 bg-gray-50 border border-gray-200 rounded-lg hover:border-gray-300 transition-colors"
        >
          <div class="flex-1">
            <p class="text-lg font-semibold text-neutral-900">
              {{ getPackagePrices(pkg) }}
            </p>
            <p class="text-base text-primary-600 font-medium mt-1">
              {{ formatNumber(pkg.credits) }} credits
            </p>
          </div>
          <div class="flex gap-2">
            <button
              @click="openEditModal(index)"
              class="btn-secondary btn-sm"
            >
              Edit
            </button>
            <button
              @click="handleDeletePackage(index)"
              class="btn-danger btn-sm"
            >
              Delete
            </button>
          </div>
        </div>

        <div v-if="packages.length === 0" class="text-center py-8 text-gray-500">
          No credit packages configured
        </div>
      </div>

      <!-- Add Package Button -->
      <button
        @click="openAddModal"
        class="btn-primary w-full"
      >
        + Add Credit Package
      </button>
    </div>

    <!-- Modal -->
    <div
      v-if="showModal"
      class="fixed inset-0 z-50 flex items-center justify-center bg-black bg-opacity-50"
      @click.self="closeModal"
    >
      <div class="bg-white rounded-lg shadow-xl max-w-2xl w-full mx-4">
        <div class="px-6 py-4 border-b border-gray-200 flex items-center justify-between">
          <h3 class="text-lg font-semibold text-neutral-900">
            {{ editingIndex !== null ? 'Edit' : 'Add' }} Credit Package
          </h3>
          <button
            @click="closeModal"
            class="text-gray-400 hover:text-gray-600"
          >
            <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
            </svg>
          </button>
        </div>

        <div class="p-6 space-y-4">
          <!-- Pricing (All 3 currencies in one row) -->
          <div>
            <label class="input-label mb-3">
              Pricing <span class="text-error-600">*</span>
            </label>
            <div class="grid grid-cols-3 gap-3">
              <!-- USD Price -->
              <div>
                <label class="text-xs font-medium text-gray-700 mb-1 block">USD ($)</label>
                <div class="relative">
                  <span class="absolute left-3 top-1/2 -translate-y-1/2 text-gray-500 text-sm">$</span>
                  <input
                    v-model.number="packageForm.price_usd"
                    type="number"
                    min="0.01"
                    step="0.01"
                    class="input-field pl-7 text-sm"
                    :class="{ 'border-error-500': packageErrors.price_usd }"
                    placeholder="5.00"
                  >
                </div>
                <p v-if="packageErrors.price_usd" class="input-error text-xs">{{ packageErrors.price_usd }}</p>
              </div>

              <!-- EUR Price -->
              <div>
                <label class="text-xs font-medium text-gray-700 mb-1 block">EUR (€)</label>
                <div class="relative">
                  <span class="absolute left-3 top-1/2 -translate-y-1/2 text-gray-500 text-sm">€</span>
                  <input
                    v-model.number="packageForm.price_eur"
                    type="number"
                    min="0.01"
                    step="0.01"
                    class="input-field pl-7 text-sm"
                    :class="{ 'border-error-500': packageErrors.price_eur }"
                    placeholder="5.00"
                  >
                </div>
                <p v-if="packageErrors.price_eur" class="input-error text-xs">{{ packageErrors.price_eur }}</p>
              </div>

              <!-- XOF Price -->
              <div>
                <label class="text-xs font-medium text-gray-700 mb-1 block">XOF (FCFA)</label>
                <div class="relative">
                  <input
                    v-model.number="packageForm.price_xof"
                    type="number"
                    min="1"
                    step="1"
                    class="input-field pr-14 text-sm"
                    :class="{ 'border-error-500': packageErrors.price_xof }"
                    placeholder="5000"
                  >
                  <span class="absolute right-3 top-1/2 -translate-y-1/2 text-gray-500 text-xs">FCFA</span>
                </div>
                <p v-if="packageErrors.price_xof" class="input-error text-xs">{{ packageErrors.price_xof }}</p>
              </div>
            </div>
            <p class="input-hint mt-2">At least one price is required. Leave fields empty to skip that currency.</p>
          </div>

          <!-- Credits -->
          <div>
            <label class="input-label">
              Credits <span class="text-error-600">*</span>
            </label>
            <input
              v-model.number="packageForm.credits"
              type="number"
              min="1"
              step="1"
              class="input-field"
              :class="{ 'border-error-500': packageErrors.credits }"
              placeholder="250"
            >
            <p v-if="packageErrors.credits" class="input-error">{{ packageErrors.credits }}</p>
            <p v-else class="input-hint">Number of credits included in this package</p>
          </div>
        </div>

        <div class="px-6 py-4 border-t border-gray-200 flex justify-end gap-2">
          <button
            @click="closeModal"
            class="btn-ghost"
          >
            Cancel
          </button>
          <button
            @click="handleSavePackage"
            class="btn-primary"
          >
            {{ editingIndex !== null ? 'Update' : 'Add' }} Package
          </button>
        </div>
      </div>
    </div>
  </div>
</template>
