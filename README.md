# Drilly Mod

**Drilly** is a Factorio mod that provides a graphical interface to inspect electric mining drills on different surfaces. It allows players to view a summary of mining drills based on the resource they are extracting and on which surface. The mod also provides a dynamic count of mining drills for each selected resource.

## Features

- **Drill Summary by Resource Type**: Displays the number of drills mining each resource type.
- **Surface Selection**: Choose from all available surfaces in the game (e.g., `nauvis` or modded surfaces).
- **Resource Filtering**: Select specific resources (e.g., `iron-ore`, `copper-ore`) to filter drill counts.
- **Dynamic Refresh**: Use the "Refresh" button to update the displayed data.

## Usage

1. **Open the Drill Inspector GUI**:
   - Open the console in Factorio by pressing `~` or `/`.
   - Type the following command to open the inspector GUI:
     ```
     /drill_inspector
     ```

2. **Choose a Surface and Resource**:
   - Select a surface from the dropdown (e.g., `nauvis`).
   - Select a resource type from the dropdown (e.g., `iron-ore`).

3. **Refresh the Display**:
   - Click the "Refresh" button to see how many drills are actively mining the selected resource on the chosen surface.

## Installation

1. Download the mod and place the `drilly` folder into the `Factorio/mods/` directory:
   - `C:\Users\<YourUsername>\AppData\Roaming\Factorio\mods` (on Windows)
   - `~/.factorio/mods/` (on Linux)
   
2. Launch Factorio and ensure the `Drilly` mod is enabled in the mod settings.

## Development

To reload the mod without restarting Factorio, use the following command in the console:
```
/c game.reload_mods()
```

## License

This mod is released under the MIT License.