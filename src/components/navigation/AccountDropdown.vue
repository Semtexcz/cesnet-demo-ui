<template lang="pug">
div
  q-btn-dropdown.account-dropdown(
    unelevated
    no-wrap
    clickable
    size="sm"
    text-color="white"
    v-if="loggedIn")
    template(v-slot:label)
      .row.items-center.no-wrap.q-gutter-sm.q-py-xs
        q-avatar(size="md")
          img(src="https://cdn.quasar.dev/img/boy-avatar.png")
        .text-caption {{ auth.user_info.name }}
    q-list(bordered padding dark).account-dropdown__list.text-white.rounded-borders
      q-item(clickable)
        locale-switcher.full-width
      q-item(clickable v-close-popup @click="showRecordCreate")
        q-item-section
          q-item-label {{ $t('labels.createRecordBtn') }}
        q-item-section(side)
          q-avatar(square icon="add" text-color="white")
      q-separator(inset dark)
      q-item(clickable v-close-popup @click="logout")
        q-item-section
          q-item-label {{ $t('labels.logoutBtn') }}
        q-item-section(side)
          q-avatar(square icon="exit_to_app" text-color="white")
</template>

<script>
import { Component, Emit, Vue } from 'vue-property-decorator'
import RecordCreateDialog from 'components/records/RecordCreateDialog'
import LocaleSwitcher from 'components/i18n/LocaleSwitcher'

export default @Component({
  name: 'AccountDropdown',
  components: {
    RecordCreateDialog,
    LocaleSwitcher
  },
  props: {
    query: Object
  }
})
class AccountDropdown extends Vue {
  get loggedIn () {
    return this.auth$.loggedLocally
  }

  get auth () {
    return this.auth$.authInfo
  }

  showRecordCreate () {
    this.$q.dialog({
      component: RecordCreateDialog,
      maximized: true,
      persistent: true,
      parent: this,
      title: this.$t('labels.createNew')
    }).onOk(data => {
      this.recordsChanged()
    })
  }

  @Emit('create-record')
  doCreateRecord () { }

  @Emit('change-record')
  recordsChanged () { }

  @Emit('logout')
  logout () {
    window.location = this.auth$.authLogoutURL
  }
}
</script>

<style lang="sass" scoped>
.account-dropdown
  &__list
    background-color: $dark-accent
</style>
