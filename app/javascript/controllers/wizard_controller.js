import { Controller } from "@hotwired/stimulus"

const SUBDOMAINS = {
  financial_services: [
    { value: "payments",       label: "Payments" },
    { value: "credit_lending", label: "Credit / Lending" },
    { value: "digital_account",label: "Digital account (BaaS)" },
    { value: "investments",    label: "Investments" },
  ],
  ecommerce_marketplace: [
    { value: "d2c",          label: "Own store (D2C)" },
    { value: "marketplace",  label: "Marketplace" },
    { value: "omnichannel",  label: "Omnichannel retail" },
    { value: "subscription", label: "Subscription" },
  ],
  saas_b2b: [
    { value: "productivity_tool", label: "Productivity tool" },
    { value: "vertical_platform", label: "Vertical platform" },
    { value: "infra_devtool",     label: "Infra / DevTool" },
  ],
  healthtech: [
    { value: "telemedicine",      label: "Telemedicine" },
    { value: "ehr_records",       label: "Health records / EHR" },
    { value: "clinic_management", label: "Clinic management" },
    { value: "medical_device",    label: "Medical device" },
  ],
  internal_systems: [
    { value: "internal_ops",       label: "Internal operations" },
    { value: "legacy_integration", label: "Legacy integration" },
    { value: "dashboard_bi",       label: "Dashboard / BI" },
    { value: "process_automation", label: "Process automation" },
  ],
}

// Ford: domain concern → candidate architectural characteristics
const CONCERN_CHARACTERISTICS = {
  time_to_market:        ["agility", "testability", "deployability"],
  user_satisfaction:     ["performance", "availability", "fault_tolerance", "testability", "deployability", "agility", "security"],
  competitive_advantage: ["agility", "testability", "deployability", "scalability", "availability", "fault_tolerance"],
  time_and_budget:       ["simplicity", "feasibility"],
  mergers_acquisitions:  ["interoperability", "scalability", "adaptability", "extensibility"],
}

const MAX_CONCERNS = 3

export default class extends Controller {
  static targets = [
    "step", "stepItem",
    "subdomainOptions",
    "concernCheckbox", "concernCounter",
    "nextButton", "backButton",
    "progressFill", "progressText",
  ]
  static values = { current: { type: Number, default: 1 } }

  connect() {
    this.selectedDomain = null
    this.totalSteps = this.stepTargets.length
    this.render()
  }

  // ── Navigation ────────────────────────────────────────────

  next() {
    if (!this.canProceed()) return

    if (this.currentValue < this.totalSteps) {
      this.currentValue++
      this.render()
    } else {
      this.element.closest("form").requestSubmit()
    }
  }

  back() {
    if (this.currentValue > 1) {
      this.currentValue--
      this.render()
    }
  }

  // ── Step 1: domain ────────────────────────────────────────

  selectDomain(event) {
    this.selectedDomain = event.target.value
    this.nextButtonTarget.disabled = false
  }

  // ── Step 2: subdomain ─────────────────────────────────────

  selectSubdomain() {
    this.nextButtonTarget.disabled = false
  }

  populateSubdomains(domain) {
    const options = SUBDOMAINS[domain] || []
    this.subdomainOptionsTarget.innerHTML = options.map(opt => `
      <label class="wizard-option">
        <input type="radio" name="project[subdomain]" value="${opt.value}"
               data-action="wizard#selectSubdomain">
        <span>${opt.label}</span>
      </label>
    `).join("")
  }

  // ── Step 3: concerns ──────────────────────────────────────

  selectConcern() {
    const checked = this.checkedConcerns()

    // enforce max
    if (checked.length > MAX_CONCERNS) {
      event.target.checked = false
    }

    this.refreshConcernUI()
  }

  checkedConcerns() {
    return this.concernCheckboxTargets.filter(cb => cb.checked)
  }

  candidateCharacteristics() {
    const selected = this.checkedConcerns().map(cb => cb.value)
    const all = selected.flatMap(key => CONCERN_CHARACTERISTICS[key] || [])
    return [...new Set(all)]
  }

  refreshConcernUI() {
    const count = this.checkedConcerns().length
    const atMax = count >= MAX_CONCERNS

    this.concernCounterTarget.textContent =
      `${count} of ${MAX_CONCERNS} selected`

    this.concernCheckboxTargets.forEach(cb => {
      const label = cb.closest(".wizard-option--check")
      cb.disabled = atMax && !cb.checked
      label.classList.toggle("wizard-option--selected",  cb.checked)
      label.classList.toggle("wizard-option--disabled",  atMax && !cb.checked)
    })

    this.nextButtonTarget.disabled = count === 0
  }

  // ── Step 4: magnifiers ────────────────────────────────────

  selectMagnifier() {
    this.nextButtonTarget.disabled = !this.canProceed()
  }

  // ── Step 5: constraints ───────────────────────────────────

  selectConstraint() {
    this.nextButtonTarget.disabled = !this.canProceed()
  }

  // ── Guards ────────────────────────────────────────────────

  canProceed() {
    const step = this.currentValue
    if (step === 1) return !!this.element.querySelector('input[name="project[domain]"]:checked')
    if (step === 2) return !!this.element.querySelector('input[name="project[subdomain]"]:checked')
    if (step === 3) return this.checkedConcerns().length > 0
    if (step === 4) {
      const fields = [
        "project[expected_users]",
        "project[growth_rate]",
        "project[traffic_pattern]",
        "project[criticality]",
      ]
      return fields.every(name =>
        !!this.element.querySelector(`input[name="${name}"]:checked`)
      )
    }
    if (step === 5) {
      // architecture_style is optional (has a "none" option), so not strictly required —
      // but since "none" is an explicit radio choice, we require all 5 fields.
      const fields = [
        "project[team_size]",
        "project[team_experience]",
        "project[budget]",
        "project[legacy_integration]",
        "project[architecture_style]",
      ]
      return fields.every(name =>
        !!this.element.querySelector(`input[name="${name}"]:checked`)
      )
    }
    return false
  }

  // ── Render ────────────────────────────────────────────────

  render() {
    const current = this.currentValue

    this.stepTargets.forEach(el => {
      el.hidden = parseInt(el.dataset.step) !== current
    })

    this.stepItemTargets.forEach(el => {
      const n = parseInt(el.dataset.step)
      el.classList.toggle("active",    n === current)
      el.classList.toggle("completed", n < current)
    })

    this.backButtonTarget.style.visibility = current === 1 ? "hidden" : "visible"

    const isLast = current === this.totalSteps
    this.nextButtonTarget.textContent = isLast ? "Analyze →" : "Next ›"
    this.nextButtonTarget.disabled = !this.canProceed()

    const pct = Math.round((current / this.totalSteps) * 100)
    this.progressFillTarget.style.width = `${pct}%`
    this.progressTextTarget.textContent =
      `Question ${current} of ${this.totalSteps} • ${pct}%`

    if (current === 2 && this.selectedDomain) {
      this.populateSubdomains(this.selectedDomain)
    }

    if (current === 3) {
      this.refreshConcernUI()
    }
  }
}
