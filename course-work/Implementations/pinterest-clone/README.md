# Pinterest Clone - Платформа за визуално вдъхновение

## Информация за студента
- **Факултетен номер**: 2301321021
- **Проект**: Pinterest Clone
- **Дисциплина**: Софтуерно моделиране и анализ

## Описание на проекта

Pinterest Clone е платформа за споделяне и организиране на визуално съдържание (изображения, идеи, вдъхновение) чрез персонализирани колекции (boards). Платформата позволява на потребителите да:

- Създават и споделят pins (публикации с изображения)
- Организират pins в boards (колекции)
- Следват други потребители
- Коментират и запазват съдържание
- Търсят по категории и тагове

## Структура на проекта

```
pinterest-clone/
├── README.md                    # Този файл
├── diagrams/
│   ├── conceptual-model.drawio  # Концептуален модел (Chen's notation)
│   ├── logical-model.drawio     # Логически модел (Crow's Foot notation)
│   └── data-warehouse.drawio    # Data Warehouse модел (UML notation)
├── database/
│   ├── 01-schema.sql            # CREATE TABLE statements
│   ├── 02-procedures.sql        # Stored procedures, functions, triggers
│   └── 03-sample-data.sql       # Sample data insertion
├── data-warehouse/
│   └── dw-schema.sql            # Data Warehouse schema
└── powerbi/
    └── README.md                # Инструкции за Power BI
```

## Технологии

- **База данни**: MS SQL Server
- **Диаграми**: draw.io
- **BI инструмент**: Power BI

## Инсталация и стартиране

### Предварителни изисквания
- MS SQL Server (2019 или по-нова версия)
- SQL Server Management Studio (SSMS)
- Power BI Desktop

### Стъпки за инсталация

1. **Клониране на репозиторито**
   ```bash
   git clone https://github.com/[username]/software-modeling-and-analysis-se.git
   cd software-modeling-and-analysis-se/course-work/Implementations/pinterest-clone
   ```

2. **Създаване на базата данни**
   ```sql
   -- Изпълнете в SSMS последователно:
   -- 1. database/01-schema.sql
   -- 2. database/02-procedures.sql
   -- 3. database/03-sample-data.sql
   ```

3. **Създаване на Data Warehouse**
   ```sql
   -- Изпълнете: data-warehouse/dw-schema.sql
   ```

4. **Power BI**
   - Отворете Power BI Desktop
   - Свържете се към SQL Server базата данни
   - Следвайте инструкциите в powerbi/README.md

## Модели на данни

### Основни обекти (8 entities)
1. **Users** - потребители на платформата
2. **Pins** - публикуваното съдържание
3. **Boards** - колекции от pins
4. **Categories** - категории за класификация
5. **Comments** - коментари към pins
6. **Tags** - тагове за търсене
7. **User_Follows** - връзка между потребители (followers)
8. **Board_Collaborators** - съвместни boards

### Връзки много-към-много
- Users ↔ Pins (чрез Pin_Saves)
- Boards ↔ Pins (чрез Board_Pins)
- Pins ↔ Tags (чрез Pin_Tags)
- Users ↔ Users (чрез User_Follows)
- Users ↔ Boards (чрез Board_Collaborators)