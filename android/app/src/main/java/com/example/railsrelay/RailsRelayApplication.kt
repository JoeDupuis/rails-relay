package com.example.railsrelay

import android.app.Application
import dev.hotwire.core.config.Hotwire
import dev.hotwire.core.turbo.config.PathConfiguration
import dev.hotwire.navigation.config.registerFragmentDestinations
import dev.hotwire.navigation.config.registerRouteDecisionHandlers
import dev.hotwire.navigation.routing.AppNavigationRouteDecisionHandler
import dev.hotwire.navigation.routing.BrowserTabRouteDecisionHandler
import dev.hotwire.navigation.routing.SystemNavigationRouteDecisionHandler

class RailsRelayApplication : Application() {
    override fun onCreate() {
        super.onCreate()
        configureApp()
    }

    private fun configureApp() {
        Hotwire.config.debugLoggingEnabled = BuildConfig.DEBUG
        Hotwire.config.webViewDebuggingEnabled = BuildConfig.DEBUG

        Hotwire.registerRouteDecisionHandlers(
            ActiveStorageRouteDecisionHandler(),
            AppNavigationRouteDecisionHandler(),
            BrowserTabRouteDecisionHandler(),
            SystemNavigationRouteDecisionHandler()
        )

        Hotwire.registerFragmentDestinations(
            WebFragment::class
        )

        Hotwire.loadPathConfiguration(
            context = this,
            location = PathConfiguration.Location(
                assetFilePath = "json/path-configuration.json",
                remoteFileUrl = "${BuildConfig.SERVER_URL}/configurations/android_v1"
            )
        )
    }
}
