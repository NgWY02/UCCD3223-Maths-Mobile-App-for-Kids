## 📱 Mobile App - Maths for Kids

📄 [Click here to view the UI Design Report (PDF)](https://github.com/NgWY02/UCCD3223-Maths-Mobile-App-for-Kids/blob/main/Report.pdf)

graph TD

    % --- Define Actors ---
    User(User)
    Admin(Admin)

    % --- Define UI Components ---
    UI_User[Mobile App (User)]
    UI_Admin[Web Admin Portal (Admin)]

    % --- Define Core Services ---
    LM[Localization Module]
    NM[Navigation Module]
    MM[Map Management Service]
    UM[User Management Service]

    % --- Define Map Management Internal APIs ---
    MM_Upload[Map Upload API]
    MM_Location[Location Creation/Mgmt API]
    MM_Route[Route Creation/Mgmt API]

    % --- Define Data Stores ---
    Cache[(Cache)]
    DB[(Database)]

    % --- Define External Inputs ---
    Sensors[/Device Sensors (WiFi, BLE, IMU)/]

    % --- Group Components in Subgraphs ---
    subgraph "User Interfaces"
        UI_User
        UI_Admin
    end

    subgraph "Core Services"
        LM
        NM
        MM
        UM
    end

    subgraph "Map Management Internals (within MM Service)"
        MM_Upload
        MM_Location
        MM_Route
    end

    subgraph "Data Layer"
        Cache
        DB
    end

    subgraph "External Inputs"
        Sensors
    end

    % --- Define Connections ---
    User --> UI_User
    Admin --> UI_Admin

    UI_User -- Login/Profile --> UM
    UI_User -- Request Position --> LM
    UI_User -- Request Route --> NM
    UI_Admin -- Manage Users --> UM
    UI_Admin -- Manage Maps/Locations/Routes --> MM

    MM --> MM_Upload % Indicate MM exposes these APIs
    MM --> MM_Location
    MM --> MM_Route

    LM -- Needs Map Data/Locations --> Cache
    NM -- Needs Map/Route Data --> Cache

    LM <--> NM  # Position Update / Context

    Sensors -- Sensor Readings --> LM

    MM_Upload -- Store Map Data --> Cache
    MM_Location -- Store Location Data --> Cache
    MM_Route -- Store Route Data --> Cache

    UM -- Store/Read User Data --> Cache

    Cache -- Read/Write Miss/Persist --> DB # Cache talks to DB for misses/writes
