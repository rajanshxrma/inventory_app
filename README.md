# Inventory Manager

Flutter app for Activity 15. Uses Firestore for inventory management with real-time sync.

## What it does
- add, edit, delete items from firestore
- real-time updates with StreamBuilder
- form validation on all fields
- separate model and service layers

## Enhanced Features

1) **Search & Filter** - theres a search bar that filters items by name and category as you type

2) **Sorting** - you can sort by name, price, quantity, or category from the menu. tapping the same option again flips between ascending/descending

## How to run
1. `flutter pub get`
2. set up firebase with `flutterfire configure`
3. create an `items` collection in firestore
4. `flutter run`
