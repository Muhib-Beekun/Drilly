# Drilly Mod

**Drilly** is a sophisticated Factorio mod designed to provide an intuitive graphical interface for inspecting and managing resource miners across multiple surfaces. Whether you're overseeing a single planet or navigating through various asteroid belts, Drilly offers comprehensive insights into your resource extraction operations, enhancing your gameplay experience through efficient monitoring and management.

## 🌟 Features

- **Comprehensive Drill Summary by Resource Type**: Instantly view the number of drills mining each specific resource, allowing for quick assessments and optimizations.

- **Surface Selection & Management**: Seamlessly switch between different surfaces or aggregate data across all surfaces to maintain a holistic view of your mining operations.

- **Resource Visualization**: Visual representations of resources with real-time data on the total amount being mined, facilitating easier tracking and decision-making.

- **Drill Type Breakdown**: Detailed counts of each drill type dedicated to mining specific resources, helping you balance and optimize your mining infrastructure.

- **Dynamic & Auto-Refresh**:
  - **Manual Refresh**: Use the "Refresh" button to update the displayed data on-demand.
  - **Configurable Auto-Refresh**: Set automatic update intervals in the mod settings to keep your data current without manual intervention.

- **Optimized Performance**: Drilly processes drills efficiently by updating only active drills or those that have recently changed status, ensuring minimal impact on game performance.

- **Progress Indicators**: Visual progress bars and indicators provide real-time feedback on the processing status of your drills.

- **User-Friendly GUI**: Intuitive and responsive graphical interface designed for ease of use, with clear categorization and actionable insights.

## 🛠 Installation

1a. **Download the Mod**:
   - Obtain the latest version of Drilly from the [Factorio Mod Portal](https://mods.factorio.com/mod/Drilly) or your preferred source.

1b. **Install the Mod**:
   - Extract the `drilly` folder into your Factorio mods directory:
     - **Windows**: `C:\Users\<YourUsername>\AppData\Roaming\Factorio\mods`
     - **Linux**: `~/.factorio/mods/`
     - **macOS**: `~/Library/Application Support/factorio/mods/`

2. **Enable the Mod**:
   - Launch Factorio.
   - Navigate to the **Mods** section in the main menu.
   - Ensure that **Drilly** is enabled.

3. **Start the Game**:
   - Enter your game world and begin utilizing Drilly's features to monitor your resource miners.

## 🎮 Usage

1. **Access the Drill Inspector GUI**:
   - **Via Interface**: Click the **Drilly** button added to your game’s toolbar.

2. **Select a Surface**:
   - Choose a specific surface from the dropdown menu or select "By Surface"/"Aggregate" to view dis/aggregated data across all surfaces.

3. **View Resource and Drill Data**:
   - **Resource Rows**: Each row displays a resource icon, the total amount being mined, and a breakdown of drill types assigned to that resource.
   - **Visual Indicators**: Use color-coded buttons to quickly assess the status of each drill:
     - **Green**: Drills are actively working.
     - **Yellow**: Drills are experiencing minor issues (e.g., waiting for space in destination).
     - **Red**: Drills are facing critical problems (e.g., no power, insufficient resources).

4. **Manage Drill Data**:
   - **Manual Refresh**: Click the green refresh button to update the data immediately.
   - **Auto-Refresh Settings**: Adjust the auto-refresh interval in the mod settings to control how frequently Drilly updates the data automatically.

5. **Monitor Processing Progress**:
   - **Progress Bars**: Observe real-time progress indicators showing the current processing status of your drills.

6. **Close the GUI**:
   - Click the red close button to hide the Drilly interface when not needed.

## ⚙️ Configuration

- **Auto-Refresh Interval**:
  - Navigate to the mod settings to adjust the frequency at which Drilly automatically refreshes the drill data.
  - Set the interval in minutes to balance between real-time updates and game performance.

## 🛠 Development

To facilitate rapid development and testing without restarting Factorio, use the following command to reload the mod:

```lua
/c game.reload_mods()
