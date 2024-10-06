# Drilly Mod

**Drilly** is a Factorio mod that provides a graphical interface to inspect electric mining drills across different surfaces. It allows players to view a summary of mining drills based on the resources they are extracting and their locations.

## Features

- **Drill Summary by Resource Type**: Displays the number of drills mining each resource type.
- **Surface Selection**: Choose from all available surfaces in the game or view data for all surfaces at once.
- **Resource Visualization**: Shows resource icons with the total amount being mined.
- **Drill Type Breakdown**: Displays the count of each drill type mining a specific resource.
- **Dynamic Refresh**: Use the "Refresh" button to update the displayed data.
- **Auto-Refresh**: Automatically updates the display at configurable intervals.

## Usage

1. **Access the Drill Inspector GUI**:
   - Click the Drilly button added to your game interface, or
   - Use the `/drilly` command in the console (press `~` or `/` to open)

2. **Choose a Surface**:
   - Select a specific surface or "All" from the dropdown menu.

3. **View Resource and Drill Data**:
   - Each row shows a resource icon, total amount being mined, and drill type counts.

4. **Refresh the Display**:
   - Click the green refresh button to manually update the data.

5. **Close the GUI**:
   - Use the red close button to hide the Drilly interface.

## Installation

1. Download the mod and place the `drilly` folder into your Factorio mods directory:
   - `C:\Users\<YourUsername>\AppData\Roaming\Factorio\mods` (on Windows)
   - `~/.factorio/mods/` (on Linux)
   
2. Launch Factorio and enable the `Drilly` mod in the mod settings.

## Configuration

- Auto-refresh settings can be adjusted in the mod settings menu.

## Development

To reload the mod without restarting Factorio, use the following command in the console:

```
/c game.reload_mods()
```

## License

This mod is released under the MIT License.