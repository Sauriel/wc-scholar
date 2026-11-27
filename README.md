# WC Scholar — Your personal library in Azeroth

Azeroth is full of stories. Some sit on dusty shelves, others wait in forgotten ruins or arrive as handwritten letters.

**WC Scholar** preserves the books, letters and notes you read, letting you return to them later in your own in-game library.

## Features

*   **Automatic collection:** Saves pages as you open them in the game's reading window.
*   **Library interface:** Browse your collection with a dark catalogue and a warm, light reading page.
*   **Full-text search:** Find titles, passages and discovery locations.
*   **Catalogue filters:** Switch between all books, favourites and unread works. Unread uses the reading status, not whether all pages have been collected.
*   **Optional narration:** With [Spoken Readables](https://github.com/rusty-key/spoken-wow/tree/master/addons/Spoken_Readables) and a matching audio pack, the **Play** button next to Favourite starts narration from the displayed page.
*   **Reading bookmarks:** Resume at your last viewed page.
*   **Adjustable text size:** Make reading more comfortable.
*   **Collection tooltips:** Collected titles show green when complete and orange when pages are missing.
*   **Movable minimap button:** Open your library with a click, or hide the button in Settings.
*   **Optional text export:** Copy individual books or your entire collection into a text editor.
*   **German and English interface:** Automatic language selection or a manual choice in Settings.
*   **Account-wide collection:** Share your library between characters in the same WoW installation.

## Getting started

Open the library with `**/wcscholar**` or left-click its minimap button.

Read a book, letter or note normally in the game. WC Scholar collects each page you open—even while the library is closed.

**For multi-page books, browse through every page once.** Pages you have not opened cannot be saved, and incomplete works remain marked accordingly.

Right-click the minimap button or use `**/wcscholar settings**` to open Settings.

## Text export

Export buttons are hidden by default and can be enabled in Settings.

The export window provides selectable text that you can copy into a text editor and save as a `.txt` file. The addon does not write text files directly.

## Compatibility and scope

Designed for **World of Warcraft: Forever**. No additional addons are required.

WC Scholar collects texts displayed in the game's standard book and letter reading window. Quest dialogue, ordinary NPC conversations and item descriptions are not collected.

Book contents remain in their original language. Tooltip status is matched against collected titles; identically named editions cannot always be distinguished before opening them.

This addon is under active development. When reporting a problem, please include your addon version, client build and any Lua error message.

## Releasing a new version

1. Update the version in `WCScholar.toc` and `Core.lua` and add a matching `## X.Y.Z` section to `CHANGELOG.md`.
2. Commit and push the release changes, including any new add-on files. To build a preview ZIP locally, run `python3 scripts/package_release.py` from the repository. It packages tracked add-on files from the working tree into `dist/WCScholar-X.Y.Z.zip`.
3. Tag the release commit and push the tag (replace `1.5.0` with the version you're releasing):

   ```sh
   git tag -a v1.5.0 -m "WC Scholar 1.5.0"
   git push origin v1.5.0
   ```

GitHub Actions publishes a release with the installable ZIP and the matching changelog entry. The ZIP contains a top-level `WCScholar/` directory and no standalone Markdown or license files; the MIT notice is included in the packaged `Core.lua`. You can download the same ZIP for manual upload to CurseForge.
