# 🌍 Wonders Map App
![Bike Animation](https://img.shields.io/badge/platform-Flutter-blue) ![X Follow](https://img.shields.io/twitter/follow/martinoyovo.svg?style=social)

A Flutter application that showcases wonders around the world using **ArcGIS Maps SDK** for seamless map integration.

## Preview

|              Initial view             |             Expand Page           |             Map Selection           |
| :----------------------------------: | :----------------------------------: | :----------------------------------: |
| <img src="https://raw.githubusercontent.com/martinoyovo/wonders_map_arcgis/refs/heads/main/screenshots/1.png" width="350"> | <img src="https://raw.githubusercontent.com/martinoyovo/wonders_map_arcgis/refs/heads/main/screenshots/2.png" width="350"> | <img src="https://raw.githubusercontent.com/martinoyovo/wonders_map_arcgis/refs/heads/main/screenshots/3.png" width="350"> |

## 🚀 Getting Started

### 1. Clone the Repository

```bash
git clone https://github.com/martinoyovo/wonders_map_arcgis.git
cd wonders_map_arcgis
```

### 2. Install ArcGIS Maps Core

Run the following command to install the necessary ArcGIS dependencies:

```bash
dart run arcgis_maps install
```

> ⚠️ Note for Windows Users:
> 
> 
> This step requires permission to create symbolic links. Either:
> 
- Run the command in an elevated **Administrator Command Prompt**, or
- Enable **Developer Mode** by going to:
    
    `Settings > Update & Security > For Developers` and turning on **Developer Mode**.
    

---

## 🔑 Configure an API Key

To enable map functionality, you need to generate an **API Key** with appropriate privileges.

1. Follow the [Create an API Key Tutorial](https://developers.arcgis.com/documentation/mapping-apis-and-services/security/api-keys/).
2. Ensure that you set the **Location Services** privileges to **Basemap**.
3. Copy the generated API key, as it will be used in the next step.

---

### 3. Create `env.json`

Create a file named `env.json` in the root directory of your project with the following format:

```json
{
    "API_KEY": "your_api_key_here"
}
```

---

## 🛠️ Run the Project

### 4. Clean and Install Dependencies

```bash
flutter clean && flutter pub get
```

### 5. Run the Application

To run the app using the `env.json` file, use:

```bash
flutter run --dart-define-from-file=path/to/env.json
```

## 📚 System Requirements

- **Dart:** 3.5.3+
- **Flutter:** 3.24.3+
- ArcGIS Maps SDK properly configured for map rendering. 

For more information, view the detailed [system requirements](https://developers.arcgis.com/flutter/system-requirements/system-requirements-for-200-6/)

---

### Enjoy exploring the wonders of the world! 🌐✨
