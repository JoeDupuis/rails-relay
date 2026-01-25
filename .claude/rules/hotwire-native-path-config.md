# Hotwire Native Path Configuration

Path configuration exists in two locations that must stay in sync:

1. **Mobile app asset**: `android/app/src/main/assets/json/path-configuration.json`
2. **Rails endpoint**: `app/controllers/configurations_controller.rb` (`android_v1` action)

When modifying either file, evaluate whether the other needs the same change.
