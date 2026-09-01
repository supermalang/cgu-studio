import { createRouter, createWebHistory } from 'vue-router'
import { useAuthStore } from '@/stores/auth'

const routes = [
  {
    path: '/',
    redirect: '/calendar'
  },
  {
    path: '/auth/login',
    name: 'login',
    component: () => import('@/views/auth/LoginView.vue'),
    meta: { requiresGuest: true }
  },
  {
    path: '/auth/signup',
    name: 'signup',
    component: () => import('@/views/auth/SignupView.vue'),
    meta: { requiresGuest: true }
  },
  {
    path: '/auth/reset-password',
    name: 'reset-password',
    component: () => import('@/views/auth/PasswordResetView.vue'),
    meta: { requiresGuest: true }
  },
  {
    path: '/calendar',
    name: 'calendar',
    component: () => import('@/views/content/ContentCalendarView.vue'),
    meta: { requiresAuth: true }
  },
  {
    path: '/posts/new',
    name: 'post-create',
    component: () => import('@/views/content/PostEditorView.vue'),
    meta: { requiresAuth: true }
  },
  {
    path: '/posts/:id',
    name: 'post-edit',
    component: () => import('@/views/content/PostEditorView.vue'),
    meta: { requiresAuth: true }
  },
  {
    path: '/channels',
    name: 'social-accounts',
    component: () => import('@/views/accounts/SocialAccountsView.vue'),
    meta: { requiresAuth: true }
  },
  {
    path: '/projects',
    name: 'projects',
    component: () => import('@/views/projects/ProjectIndexView.vue'),
    meta: { requiresAuth: true }
  },
  {
    path: '/projects/new',
    name: 'project-create',
    component: () => import('@/views/projects/ProjectCreateView.vue'),
    meta: { requiresAuth: true }
  },
  {
    path: '/dashboard',
    name: 'dashboard',
    component: () => import('@/views/dashboard/DashboardView.vue'),
    meta: { requiresAuth: true }
  },
  {
    path: '/avatars',
    name: 'avatars',
    component: () => import('@/views/avatars/AvatarLibraryView.vue'),
    meta: { requiresAuth: true }
  },
  {
    path: '/environments',
    name: 'environments',
    component: () => import('@/views/environments/EnvironmentsView.vue'),
    meta: { requiresAuth: true }
  },
  {
    path: '/environments/new',
    name: 'environment-create',
    component: () => import('@/views/environments/EnvironmentCreateView.vue'),
    meta: { requiresAuth: true }
  },
  {
    path: '/environments/:id',
    name: 'environment-detail',
    component: () => import('@/views/environments/EnvironmentDetailView.vue'),
    meta: { requiresAuth: true }
  },
  {
    path: '/environments/:id/edit',
    name: 'environment-edit',
    component: () => import('@/views/environments/EnvironmentEditView.vue'),
    meta: { requiresAuth: true }
  },
  {
    path: '/projects/:id',
    name: 'project-detail',
    component: () => import('@/views/projects/ProjectDetailView.vue'),
    meta: { requiresAuth: true }
  },
  {
    path: '/settings',
    name: 'settings',
    component: () => import('@/views/settings/ProfileSettings.vue'),
    meta: { requiresAuth: true }
  },
  {
    path: '/billing',
    name: 'billing',
    component: () => import('@/views/Billing.vue'),
    meta: { requiresAuth: true }
  },
  {
    path: '/admin',
    name: 'admin',
    component: () => import('@/views/admin/AdminDashboard.vue'),
    meta: { requiresAuth: true, requiresAdmin: true }
  },
  {
    path: '/admin/settings',
    name: 'admin-settings',
    component: () => import('@/views/admin/AdminSettings.vue'),
    meta: { requiresAuth: true, requiresAdmin: true }
  }
]

const router = createRouter({
  history: createWebHistory(),
  routes
})

// Track if auth has been initialized to avoid waiting on every navigation
let authInitialized = false

// Navigation guards
router.beforeEach(async (to, from, next) => {
  const authStore = useAuthStore()

  // Wait for auth to initialize only on first navigation
  if (!authInitialized && authStore.loading) {
    await new Promise(resolve => {
      const unwatch = authStore.$subscribe((mutation, state) => {
        if (!state.loading) {
          unwatch()
          authInitialized = true
          resolve()
        }
      })
    })
  } else if (!authInitialized) {
    // If not loading but not initialized yet, mark as initialized
    authInitialized = true
  }

  const requiresAuth = to.matched.some(record => record.meta.requiresAuth)
  const requiresGuest = to.matched.some(record => record.meta.requiresGuest)
  const requiresAdmin = to.matched.some(record => record.meta.requiresAdmin)

  // Check if route requires authentication
  if (requiresAuth && !authStore.isAuthenticated) {
    next({ name: 'login', query: { redirect: to.fullPath } })
    return
  }

  // Check if route is for guests only (login/signup)
  if (requiresGuest && authStore.isAuthenticated) {
    next({ name: 'calendar' })
    return
  }

  // Check if route requires admin role
  if (requiresAdmin && !authStore.isAdmin) {
    next({ name: 'dashboard' })
    return
  }

  next()
})

export default router
