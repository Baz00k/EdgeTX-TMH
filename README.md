# TMH - Telemetry Must Have

A simple telemetry script for EdgeTX radios that provides essential battery and link quality monitoring for RC models.
Useful for models without FC, but with a receiver that provides battery telemetry (like RadioMaster ER6 etc.)

## Features

-   **Battery Monitoring**

    -   Real-time battery voltage display
    -   Percentage calculation based on LiPo discharge curve
    -   Automatic cell count detection
    -   Configurable warning and critical thresholds
    -   Voice announcements at configurable percentage intervals

-   **Link Quality Monitoring**

    -   Real-time link quality display
    -   Configurable warning and critical thresholds
    -   Voice announcements for link quality issues

-   **User Interface**
    -   Clean, easy-to-read display
    -   Visual indicators for battery and link status
    -   Configurable font sizes
    -   Theme-aware colors

## Installation

1. Download the latest release from the [Releases](https://github.com/Baz00k/TMH/releases) page
2. Extract the `.zip` or `.tar.gz` file
3. Copy the `SCRIPTS` folder to your EdgeTX SD card, merging with existing folders
4. In EdgeTX, navigate to the telemetry screen setup and add the TMH script

## Configuration

The script provides sensible defaults for all of the values, but if you want to change anything,
the script can be configured by editing the `SCRIPTS/TELEMETRY/TMH/config.lua` file.

## Usage

### Basic Operation

The script will automatically display battery voltage, percentage, and link quality when added to a telemetry screen.

### Cell Count Detection

-   The script will automatically detect the number of cells in your battery if `AUTO_CELL_DETECT` is enabled
-   Press the ENTER button to reset cell detection if needed

### Voice Announcements

When enabled, the script will announce:

-   Battery percentage at intervals defined by `PERCENTAGE_STEP` (every 10% by default)
-   Warning and critical battery levels
-   Warning and critical link quality levels

## Compatibility

-   EdgeTX 2.4.0 and above
-   Tested with RadioMaster ER4 and RadioMaster Pocket

## Development

All PR's are welcome
