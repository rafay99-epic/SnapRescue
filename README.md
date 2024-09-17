# SnapRescue

**SnapRescue** is a powerful and user-friendly Bash script designed to safeguard your system with Snapper snapshots and facilitate seamless rollbacks. With SnapRescue, you can effortlessly manage your system snapshots, ensuring that you’re always prepared to recover from potential issues or configuration mishaps.

## 🚀 Features

- **Automated Snapshots**: Easily create and manage system snapshots with Snapper.
- **Seamless Rollbacks**: Roll back to a previous state with a single command if things go awry.
- **User-Friendly Interface**: Simple prompts and clear instructions guide you through the process.
- **Customizable Options**: Choose to reboot immediately or later, based on your preference.
- **Safety First**: Designed to prevent system instability and make recovery straightforward.

## 🛠️ Installation

1. **Clone the Repository**:

   ```bash
   git clone https://github.com/rafay99-epic/SnapRescue.git
   ```

2. **Navigate to the Directory**:

   ```bash
   cd SnapRescue
   ```

3. **Make the Script Executable**:
   ```bash
   chmod +x snaprescue.sh
   ```

## 🖥️ Usage

1. **Run the Script**:

   ```bash
   ./snaprescue.sh
   ```

2. **Follow the On-Screen Prompts**:
   - Review the current BTRFS partitions.
   - Choose to reboot now or later.

## 📜 **Commands**

- **Automatic Snapshots**: Snapper automatically creates a snapshot when you install, remove, or make changes to applications.

- **List All Snapshots**: To view all snapshots, run:

  ```bash
  snapper ls
  ```

- **Rollback to a Previous Snapshot**: To revert to a previous snapshot, use:

  ```bash
  sudo snapper rollback <snapper-id>
  ```

  Replace `<snapper-id>` with the ID of the snapshot, which you can find by listing all snapshots.

- **Manually Create a Snapshot**: To create a snapshot manually, use:

  ```bash
  snapper -c root create -d "<Name of the snapshot>"
  ```

  Replace `<Name of the snapshot>` with a descriptive name for the snapshot.

- **Automatic Snapshot Cleanup**: Snapshots older than 7 days are automatically deleted.

- **Access Snapshots via GRUB**: All snapshots are visible in the GRUB menu under "Arch Linux - Snapshots". To restore:

  1. Select the desired snapshot from the GRUB menu.
  2. Press Enter to boot from the snapshot.

  **Note**: Ensure you select the snapshot image in the GRUB menu, not the fallback image.

## 📝 Notes

- **Reboot Reminder**: Make sure to reboot your system to apply changes if you chose to reboot later.
- **Use with Caution**: Although SnapRescue aims to protect your system, always ensure you have recent backups before making significant changes.

## 🤝 Contributing

Contributions are welcome! If you have suggestions or improvements, please submit a pull request or open an issue.

## 📧 Contact

For any questions or support, please contact the author:

- [Abdul Rafay](https://www.rafay99.com/contact-me)

- [Sharjeel Mazhar](mailto:sharjeelmazhar@gmail.com)

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

**SnapRescue** makes system management easier and safer, ensuring that you always have a reliable way to recover from unexpected issues. Try it out and enjoy peace of mind with your system snapshots!
