# WHMCS Ticket Prevention System

## Overview

The WHMCS Ticket Prevention System is a hook for WHMCS that prevents users from opening new support tickets if they already have unresolved or active tickets. This system is useful for managing ticket load and ensuring that existing issues are addressed before new ones are submitted.

This repository includes a Bash script to facilitate the installation and removal of the prevention system and its translations.

## Features

- **Prevents multiple open tickets**: Users are prevented from creating new tickets if they already have unresolved tickets.
- **Multi-language support**: Includes translations for several languages.
- **Easy installation and removal**: The provided script simplifies the process of adding or removing the hook and translations.

## Installation

### Prerequisites

- WHMCS installed and configured.
- Access to the server where WHMCS is hosted.
- Basic knowledge of using the command line.

### Installation Steps

**Run the Script**

   Execute the script to start the installation process:

   ```
   bash <(curl -L -s https://raw.githubusercontent.com/zytakeshi/preventMultipleTicketsHookWHMCS/main/preventMultipleTickets.sh)
   ```

   Follow the prompts to provide the WHMCS installation directory and choose the appropriate options.

## Usage

Once installed, the hook will:

- **Pre-Submit Check**: Prevent the ticket submission if the user has unresolved tickets, showing an error message.
- **Post-Submit Check**: Log an error if an attempt is made to open multiple tickets, though the primary prevention is handled before submission.

### Translations

The script includes translations for the following languages:

- Chinese (Simplified and Traditional)
- English
- Farsi
- Japanese
- Spanish
- Vietnamese

These translations will be added to the corresponding language files in the WHMCS `lang` directory.

## Removing the System

To remove the prevention system, including the hook and translations, follow these steps:

1. **Run the Removal Script**

   Execute the script to remove the hook and translations:

   ```bash
   ./install_script.sh
   ```

2. **Follow the Prompts**

   Select the option to remove the prevention system and provide the WHMCS installation directory when prompted.

## Customization

You can customize the hook or translations by editing the `ticket_prevention_hook.php` file or language files directly. Ensure that any changes are tested in a staging environment before applying them to your production system.

## Troubleshooting

- **If the hook does not seem to work**, ensure that it is correctly placed in the WHMCS `includes/hooks` directory and that there are no syntax errors.
- **Check permissions**: Ensure that the script has the necessary permissions to write to the WHMCS directories.
