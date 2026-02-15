package com.example.railsrelay

import android.util.TypedValue
import androidx.browser.customtabs.CustomTabColorSchemeParams
import androidx.browser.customtabs.CustomTabsIntent
import androidx.core.net.toUri
import dev.hotwire.navigation.activities.HotwireActivity
import dev.hotwire.navigation.navigator.NavigatorConfiguration
import dev.hotwire.navigation.routing.Router

class ActiveStorageRouteDecisionHandler : Router.RouteDecisionHandler {
    override val name = "active-storage"

    override fun matches(
        location: String,
        configuration: NavigatorConfiguration
    ): Boolean {
        return location.contains("/rails/active_storage/")
    }

    override fun handle(
        location: String,
        configuration: NavigatorConfiguration,
        activity: HotwireActivity
    ): Router.Decision {
        val typedValue = TypedValue()
        activity.theme.resolveAttribute(com.google.android.material.R.attr.colorSurface, typedValue, true)
        val color = typedValue.data

        val colorParams = CustomTabColorSchemeParams.Builder()
            .setToolbarColor(color)
            .setNavigationBarColor(color)
            .build()

        CustomTabsIntent.Builder()
            .setShowTitle(true)
            .setShareState(CustomTabsIntent.SHARE_STATE_ON)
            .setUrlBarHidingEnabled(false)
            .setDefaultColorSchemeParams(colorParams)
            .build()
            .launchUrl(activity, location.toUri())

        return Router.Decision.CANCEL
    }
}
