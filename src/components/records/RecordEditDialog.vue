<template lang="pug">
q-dialog(
  ref="dialog"
  @hide="onDialogHide"
  position="top"
  maximized
  transition-hide="slide-up"
  transition-show="slide-down")
    q-card.q-dialog-plugin.recordupdate__dialog.text-white
      q-bar
        q-space
        q-btn(dense flat size="md" icon="close" v-close-popup)
          q-tooltip(content-class="bg-white text-black") {{ $t('tooltips.close') }}
      q-card-section.q-pa-xl
        .text-h5 {{ $t('labels.editRecord') }}
      q-card-section.q-pa-xl
        div(v-if="mode === modes.FORM")
          q-slide-transition(leave)
            q-form(
              @submit="submitForm"
              @reset="reset"
              class="q-gutter-md")
              q-input(
                ref="title"
                autofocus
                standout
                dark
                type="text"
                :label="$t('labels.record.title') + ' (' + $t('values.lang.csCZ') + ')'"
                :rules="[$rules.required()]"
                v-model="record.title[0].value")
              q-input(
                ref="description"
                standout
                dark
                type="text"
                :label="$t('labels.record.description')"
                :rules="[$rules.required()]"
                v-model="record.description[0].value")
              q-input(
                ref="abstract"
                standout
                dark
                type="textarea"
                :label="$t('labels.record.abstract') + ' (' + $t('values.lang.csCZ') + ')'"
                :rules="[$rules.required()]"
                v-model="record.abstract[0].value")
              q-input(
                ref="creator"
                standout
                dark
                hide-bottom-space
                type="text"
                :label="$t('labels.record.creator')"
                :rules="[$rules.required()]"
                v-model="record.creator")
              q-input(
                ref="contributor"
                standout
                dark
                type="text"
                :label="$t('labels.record.contributors')"
                v-model="record.contributor")
        div(v-else-if="mode === modes.DONE")
          .col.self-center.text-center.q-pa-lg.q-gutter-lg
            q-icon(name="cloud_done" size="xl")
            .text-h4 {{ $t('messages.recordUpdateSuccess') }}
        div(v-else-if="mode === modes.FAILURE")
          .col.self-center.text-center.q-pa-lg.q-gutter-lg
            q-icon(name="sentiment_very_dissatisfied" size="xl")
            .text-h4 {{ $t('messages.recordUpdateError') }}
            q-input.q-px-lg(v-if="errors" readonly autogrow rounded type="text" dark standout v-model="errors")
      q-inner-loading(:showing="progress" dark)
        .text-h6.q-mb-md {{ $t('messages.updatingRecord') }}&hellip;
        q-spinner-gears(size="50px" color="white")
      q-card-actions.q-px-xl.q-py-md.q-my-md
        q-space
        q-btn.q-mr-lg(
          v-if="mode !== modes.DONE"
          :disabled="progress"
          icon="undo"
          @click="reset"
          :label="$t(resetLabel)"
          flat
          size="md"
          type="reset"
          color="white")
        q-btn.q-px-md(
          v-if="mode === modes.FORM"
          :disabled="progress"
          @click="submitForm"
          icon="save"
          :label="$t('labels.submitBtn')"
          size="lg"
          type="submit"
          color="positive")
        q-btn.q-px-md(
          v-if="[modes.DONE, modes.FAILURE].includes(mode)"
          :disabled="progress"
          @click="hide"
          icon="close"
          :label="$t('labels.closeBtn')"
          size="lg"
          color="primary")
</template>

<script>
import { Component, Emit, Vue, Watch } from 'vue-property-decorator'

export default @Component({
  name: 'RecordEditDialog',
  props: {
    id: String,
    value: Object
  }
})
class RecordEditDialog extends Vue {
  modes = Object.freeze({ FORM: 0, DONE: 2, FAILURE: 3 })
  progress = false
  mode = this.modes.FORM
  errors = null

  record = {}

  created () {
    this.valueChanged()
    this.ensureAuthenticated()
  }

  frozenValue () {
    // Get a copy of props to model without reactivity watchers
    // Right now, this is probably the only working way to do it:
    // https://forum.vuejs.org/t/how-to-clone-property-value-as-simple-object/40032/3
    return JSON.parse(JSON.stringify(this.value))
  }

  @Watch('value')
  valueChanged () {
    this.record = this.frozenValue()
  }

  ensureAuthenticated () {
    if (!this.$auth.loggedLocally) {
      this.$auth.login(this)
    }
  }

  show () {
    this.$refs.dialog.show()
  }

  hide () {
    this.$refs.dialog.hide()
  }

  get resetLabel () {
    switch (this.mode) {
      case this.modes.FAILURE:
        return 'labels.tryAgainBtn'
      default:
        return 'labels.resetBtn'
    }
  }

  @Emit('hide')
  onDialogHide () {
  }

  async validate () {
    let success = false
    const resPromise = await Promise.all([
      this.$refs.title.validate(),
      this.$refs.description.validate(),
      this.$refs.abstract.validate(),
      this.$refs.contributor.validate()
    ])
    if (resPromise.reduce((a, b) => (a && b), true)) {
      success = true
    }
    return success
  }

  async submitForm () {
    const valid = await this.validate()
    if (!valid) {
      this.$q.notify({
        type: 'negative',
        message: `${this.$t('messages.validation.failed')}`
      })
      return
    }

    return this.submitRecord(this.record, this.recordUpdated, this.updateFailed)
  }

  async submitRecord (record, onSuccess, onFailed, progress = true) {
    await this.ensureAuthenticated()

    const cid = this.$oarepo.collection.collectionId
    const rid = this.id
    this.$oarepo.record.load({ collectionId: cid, recordId: rid })

    if (!this.$oarepo.record.recordId) {
      this.errors = 'Unable to fetch record data from database'
      return this.updateFailed()
    }

    const patch = this.$jsonpatch.createPatch(this.frozenValue(), record)
    console.log('Diff between records', this.frozenValue(), record, patch)
    if (patch.length === 0) {
      this.errors = 'Unable to update record data'
      return this.updateFailed()
    }

    if (progress) {
      this.progress = true
    }

    this.$oarepo.record.patch(patch)
      .then(() => {
        return onSuccess()
      })
      .catch(err => {
        return onFailed(err.response)
      })
      .finally(() => {
        this.progress = false
      })
  }

  recordUpdated (resp) {
    this.mode = this.modes.DONE
    this.$nextTick(() => setTimeout(() => {
      this.$emit('ok')
      this.hide()
    }, 1500))
    return resp
  }

  @Emit('update-failed')
  updateFailed (err) {
    if (err) {
      console.error(err)
      this.errors = err.data.message || err.data
    }
    this.mode = this.modes.FAILURE
  }

  resetValidation () {
    this.$refs.title.resetValidation()
    this.$refs.description.resetValidation()
    this.$refs.abstract.resetValidation()
    this.$refs.contributor.resetValidation()
  }

  reset () {
    this.errors = null

    if (this.mode === this.modes.FAILURE) {
      // Don't clear data on failure, let the user correct it and try again
      this.mode = this.modes.FORM
      return
    }

    // Restore original record data and validation state
    this.valueChanged()
    this.$nextTick(() => this.resetValidation())
  }
}
</script>

<!-- Add "scoped" attribute to limit CSS to this component only -->
<style lang="sass" scoped>
.recordupdate
  &__dialog
    background-color: $dark-accent
</style>
