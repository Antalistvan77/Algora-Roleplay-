# Modern Roleplay HUD Rendszer

## Leírás
Egy modern, vonzó és funkciógazdag HUD rendszer MTA San Andreas szerverekhez, kifejezetten Roleplay módokhoz optimalizálva.

## Funkciók

### 🎯 Alap HUD Elemek
- **Egészség bar**: Modern grafikai megjelenítéssel
- **Páncél bar**: Csak akkor jelenik meg, ha van páncél
- **Pénz kijelző**: Formázott pénzösszeg megjelenítés
- **Játék idő**: Aktuális játék idő megjelenítése

### 🚗 Sebességmérő Rendszer
- **Valós idejű sebesség**: km/h-ban
- **Üzemanyag kijelző**: Szín-kódolt üzemanyag bar
- **Jármű információk**: Név, állapot, motor státusz
- **Dinamikus tű**: Analóg sebességmérő tű animációval

### 🗺️ Modern Minimap
- **Közeli játékosok**: Munkahely alapú színkódolással
- **Zoom funkció**: 5 különböző zoom szint
- **Waypoint rendszer**: Egyedi útvonaljelölők
- **Iránytű**: Magyar irányjelzéssel

### 📱 Notifikációs Rendszer
- **Animált értesítések**: Smooth slide-in animációkkal
- **Típus-alapú színkódolás**: Siker, hiba, figyelmeztetés, info
- **Pénz változás animációk**: +/- pénzösszeg megjelenítése
- **Tapasztalat kijelző**: XP változások animációkkal
- **Szintlépés celebráció**: Spektákuláris szintlépés animáció

### 🏆 Achievement Rendszer
- **Eredmény notifikációk**: Különleges eredmények megjelenítése
- **Egyedi ikonok**: Minden achievementhez saját ikon
- **Animált megjelenés**: Smooth slide-in effektusok

## Telepítés

1. **Másolás**: Másold a `modern-hud` mappát a `resources/[gameplay]/` könyvtárba
2. **Aktiválás**: Add hozzá a resource-t a szerver konfigurációjához:
   ```
   <resource src="modern-hud" startup="1" protected="0" />
   ```
3. **Újraindítás**: Indítsd újra a szervert vagy használd a `/restart modern-hud` parancsot

## Parancsok

### Játékos Parancsok
- `/hud` - HUD be/kikapcsolása
- `/engine` - Motor be/kikapcsolása (járműben)
- `/minimap` - Minimap be/kikapcsolása
- `/waypoint [x] [y]` - Waypoint beállítása/törlése
- `/stats [játékos]` - Statisztikák megtekintése
- `/refuel` - Üzemanyag feltöltése ($500)

### Admin Parancsok
- `/setjob [játékos] [munka]` - Munka beállítása
- `/givemoney [játékos] [összeg]` - Pénz adása

## Billentyű Vezérlés

- **F11**: Minimap zoom váltása
- **F12**: Minimap be/ki kapcsolása

## Munkák/Foglalkozások

### Elérhető Munkák
- `civilian` - Civil (alapértelmezett)
- `police` - Rendőr (kék blip)
- `medic` - Mentős (fehér blip)
- `mechanic` - Szerelő (narancssárga blip)
- `taxi` - Taxis
- `trucker` - Kamionos
- `dealer` - Kereskedő
- `admin` - Admin

### Munka Specifikus Juttatások
- **Rendőr**: Gumibot és spray
- **Mentős**: Speciális felszerelés
- **Szerelő**: Láncfűrész

## Konfigurálás

### HUD Pozíciók
A HUD elemek pozícióit a `client/hud_client.lua` fájlban módosíthatod:

```lua
local hudConfig = {
    healthBar = {
        x = 50,
        y = screenHeight - 120,
        width = 200,
        height = 15
    },
    -- További beállítások...
}
```

### Színek Testreszabása
```lua
colors = {
    health = {255, 80, 80, 200},
    armor = {80, 150, 255, 200},
    money = {80, 255, 80, 200},
    -- További színek...
}
```

## Fejlesztői Információk

### Event Triggerek
```lua
-- Notifikáció megjelenítése
triggerClientEvent(player, "showNotification", player, "Cím", "Üzenet", "success")

-- Pénz változás animáció
triggerClientEvent(player, "showMoneyChange", player, 500, "Fizetés")

-- Tapasztalat hozzáadása
triggerClientEvent(player, "showExperienceChange", player, 50, "Küldetés")
```

### Szerver Oldali Funkciók
```lua
-- Játékos munka beállítása
setPlayerJob(player, "police")

-- Pénz hozzáadása
addPlayerMoney(player, 1000, "Jutalom")

-- Tapasztalat hozzáadása
addPlayerExperience(player, 100, "Küldetés teljesítése")
```

## Rendszerkövetelmények

- **MTA San Andreas**: 1.5.8 vagy újabb
- **Lua**: 5.1
- **Kliens oldali DX funkciók**: Engedélyezve
- **ACL jogosultságok**: 
  - `general.http`
  - `function.setPlayerHudComponentVisible`
  - `function.xmlLoadFile`
  - `function.xmlSaveFile`

## Hibaelhárítás

### Gyakori Problémák

1. **HUD nem jelenik meg**
   - Ellenőrizd az ACL jogosultságokat
   - Nézd meg a debug log-ot F8-cal

2. **Sebességmérő nem működik**
   - Győződj meg róla, hogy a jármű adatok inicializálva vannak
   - Ellenőrizd az element data-kat

3. **Minimap üres**
   - Ellenőrizd a radar jogosultságokat
   - Nézd meg, hogy vannak-e közeli játékosok

## Changelog

### v1.0.0
- Alap HUD rendszer
- Sebességmérő implementálása
- Modern minimap
- Notifikációs rendszer
- Achievement rendszer
- Szerver oldali logika

## Támogatás

Ha problémáid vannak a HUD-dal, vagy fejlesztési kérdéseid vannak:
1. Ellenőrizd a debug konzolt (F8)
2. Nézd meg a szerver log-okat
3. Ellenőrizd az ACL beállításokat

## Licensz

Ez a projekt saját fejlesztés, MTA Roleplay szerverekhez készült.

---

*Készítette: Roleplay Mod Team*  
*Verzió: 1.0.0*  
*Utolsó frissítés: 2024* 