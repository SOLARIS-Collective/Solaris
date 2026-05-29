#!/usr/bin/env python3
"""
Скрипт для обновления дефайнов в файлах системы боя
Заменяет старые дефайны на новые с префиксом SHIP_
"""

import os
import re

# Словарь замен (старый дефайн -> новый дефайн)
REPLACEMENTS = {
    # Типы вооружения
    'WEAPON_TYPE_LASER': 'SHIP_WEAPON_TYPE_LASER',
    'WEAPON_TYPE_KINETIC': 'SHIP_WEAPON_TYPE_KINETIC',
    'WEAPON_TYPE_MISSILE': 'SHIP_WEAPON_TYPE_MISSILE',
    'WEAPON_TYPE_ENERGY': 'SHIP_WEAPON_TYPE_ENERGY',
    
    # Состояния вооружения
    'WEAPON_STATE_READY': 'SHIP_WEAPON_STATE_READY',
    'WEAPON_STATE_CHARGING': 'SHIP_WEAPON_STATE_CHARGING',
    'WEAPON_STATE_FIRING': 'SHIP_WEAPON_STATE_FIRING',
    'WEAPON_STATE_DAMAGED': 'SHIP_WEAPON_STATE_DAMAGED',
    'WEAPON_STATE_DISABLED': 'SHIP_WEAPON_STATE_DISABLED',
    
    # Статусы захвата цели
    'TARGET_LOCK_NONE': 'SHIP_TARGET_LOCK_NONE',
    'TARGET_LOCK_ACQUIRING': 'SHIP_TARGET_LOCK_ACQUIRING',
    'TARGET_LOCK_LOCKED': 'SHIP_TARGET_LOCK_LOCKED',
    'TARGET_LOCK_LOST': 'SHIP_TARGET_LOCK_LOST',
    
    # Константы
    'DEFAULT_MAX_TARGET_RANGE': 'SHIP_DEFAULT_MAX_TARGET_RANGE',
    'DEFAULT_TARGET_LOCK_TIME': 'SHIP_DEFAULT_TARGET_LOCK_TIME',
    'DEFAULT_TARGET_SCAN_INTERVAL': 'SHIP_DEFAULT_TARGET_SCAN_INTERVAL',
    
    # Типы урона
    'SHIP_DAMAGE_HULL': 'SHIP_DAMAGE_HULL',
    'SHIP_DAMAGE_SYSTEMS': 'SHIP_DAMAGE_SYSTEMS',
    'SHIP_DAMAGE_SHIELDS': 'SHIP_DAMAGE_SHIELDS',
    'SHIP_DAMAGE_ENGINES': 'SHIP_DAMAGE_ENGINES',
    
    # Системы корабля
    'SHIP_SYSTEM_WEAPONS': 'SHIP_SYSTEM_WEAPONS',
    'SHIP_SYSTEM_SHIELDS': 'SHIP_SYSTEM_SHIELDS',
    'SHIP_SYSTEM_ENGINES': 'SHIP_SYSTEM_ENGINES',
    'SHIP_SYSTEM_POWER': 'SHIP_SYSTEM_POWER',
    'SHIP_SYSTEM_LIFE_SUPPORT': 'SHIP_SYSTEM_LIFE_SUPPORT',
    'SHIP_SYSTEM_COMMUNICATIONS': 'SHIP_SYSTEM_COMMUNICATIONS',
    'SHIP_SYSTEM_SENSORS': 'SHIP_SYSTEM_SENSORS',
    
    # Уровни повреждений
    'DAMAGE_LEVEL_NONE': 'SHIP_DAMAGE_LEVEL_NONE',
    'DAMAGE_LEVEL_MINOR': 'SHIP_DAMAGE_LEVEL_MINOR',
    'DAMAGE_LEVEL_MODERATE': 'SHIP_DAMAGE_LEVEL_MODERATE',
    'DAMAGE_LEVEL_SEVERE': 'SHIP_DAMAGE_LEVEL_SEVERE',
    'DAMAGE_LEVEL_CRITICAL': 'SHIP_DAMAGE_LEVEL_CRITICAL',
    'DAMAGE_LEVEL_DESTROYED': 'SHIP_DAMAGE_LEVEL_DESTROYED',
    
    # Цвета
    'COLOR_GOOD': 'SHIP_COLOR_GOOD',
    'COLOR_AVERAGE': 'SHIP_COLOR_AVERAGE',
    'COLOR_BAD': 'SHIP_COLOR_BAD',
    'COLOR_DISABLED': 'SHIP_COLOR_DISABLED',
    
    # Звуки
    'SOUND_LASER_FIRE': 'SHIP_SOUND_LASER_FIRE',
    'SOUND_KINETIC_FIRE': 'SHIP_SOUND_KINETIC_FIRE',
    'SOUND_MISSILE_FIRE': 'SHIP_SOUND_MISSILE_FIRE',
    'SOUND_ENERGY_FIRE': 'SHIP_SOUND_ENERGY_FIRE',
    'SOUND_IMPACT_EXPLOSION': 'SHIP_SOUND_IMPACT_EXPLOSION',
    'SOUND_IMPACT_LASER': 'SHIP_SOUND_IMPACT_LASER',
    'SOUND_TARGET_LOCK': 'SHIP_SOUND_TARGET_LOCK',
    'SOUND_TARGET_LOST': 'SHIP_SOUND_TARGET_LOST',
    'SOUND_WEAPON_DAMAGED': 'SHIP_SOUND_WEAPON_DAMAGED',
    'SOUND_WEAPON_REPAIRED': 'SHIP_SOUND_WEAPON_REPAIRED',
    
    # Типы кораблей
    'SHIP_TYPE_FRIGATE': 'SHIP_TYPE_FRIGATE',
    'SHIP_TYPE_DESTROYER': 'SHIP_TYPE_DESTROYER',
    'SHIP_TYPE_CRUISER': 'SHIP_TYPE_CRUISER',
    'SHIP_TYPE_BATTLESHIP': 'SHIP_TYPE_BATTLESHIP',
    'SHIP_TYPE_CARRIER': 'SHIP_TYPE_CARRIER',
    'SHIP_TYPE_TRANSPORT': 'SHIP_TYPE_TRANSPORT',
    'SHIP_TYPE_MINING': 'SHIP_TYPE_MINING',
    'SHIP_TYPE_SCIENCE': 'SHIP_TYPE_SCIENCE',
    'SHIP_TYPE_PIRATE': 'SHIP_TYPE_PIRATE',
    
    # Фракции
    'FACTION_NANOTRASEN': 'SHIP_FACTION_NANOTRASEN',
    'FACTION_SYNDICATE': 'SHIP_FACTION_SYNDICATE',
    'FACTION_SOLGOV': 'SHIP_FACTION_SOLGOV',
    'FACTION_INDEPENDENT': 'SHIP_FACTION_INDEPENDENT',
    'FACTION_PIRATE': 'SHIP_FACTION_PIRATE',
    'FACTION_ALIEN': 'SHIP_FACTION_ALIEN',
    
    # Статусы боя
    'COMBAT_STATUS_PEACEFUL': 'SHIP_COMBAT_STATUS_PEACEFUL',
    'COMBAT_STATUS_ALERT': 'SHIP_COMBAT_STATUS_ALERT',
    'COMBAT_STATUS_ENGAGED': 'SHIP_COMBAT_STATUS_ENGAGED',
    'COMBAT_STATUS_RETREATING': 'SHIP_COMBAT_STATUS_RETREATING',
    'COMBAT_STATUS_DISABLED': 'SHIP_COMBAT_STATUS_DISABLED',
    
    # Макросы
    'CAN_FIRE': 'SHIP_CAN_FIRE',
    'OVERMAP_DISTANCE': 'SHIP_OVERMAP_DISTANCE',
    'IN_RANGE': 'SHIP_IN_RANGE',
    'GET_PROGRESS': 'SHIP_GET_PROGRESS',
    'FORMAT_TIME': 'SHIP_FORMAT_TIME',
    
    # Флаги снарядов
    'PROJECTILE_FLAG_INTERCEPTABLE': 'SHIP_PROJECTILE_FLAG_INTERCEPTABLE',
    'PROJECTILE_FLAG_HOMING': 'SHIP_PROJECTILE_FLAG_HOMING',
    'PROJECTILE_FLAG_PROXIMITY': 'SHIP_PROJECTILE_FLAG_PROXIMITY',
    'PROJECTILE_FLAG_SHIELD_PIERCING': 'SHIP_PROJECTILE_FLAG_SHIELD_PIERCING',
}

def update_file(filepath):
    """Обновляет дефайны в указанном файле"""
    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            content = f.read()
        
        original_content = content
        
        # Заменяем каждый дефайн
        for old_define, new_define in REPLACEMENTS.items():
            # Используем регулярное выражение для точной замены
            # Ищем дефайн как отдельное слово (не часть другого слова)
            pattern = r'\b' + re.escape(old_define) + r'\b'
            content = re.sub(pattern, new_define, content)
        
        # Если были изменения, сохраняем файл
        if content != original_content:
            with open(filepath, 'w', encoding='utf-8') as f:
                f.write(content)
            print(f"✓ Обновлен: {filepath}")
            return True
        else:
            print(f"  Пропущен: {filepath} (нет изменений)")
            return False
    
    except Exception as e:
        print(f"✗ Ошибка в {filepath}: {e}")
        return False

def main():
    """Главная функция"""
    # Директория с файлами системы боя
    combat_dir = "code/modules/overmap/combat"
    
    # Файлы для обновления
    files_to_update = [
        "combat_system.dm",
        "ship_weapon.dm",
        "ship_projectile.dm",
        "fire_control_console.dm",
        "ship_integration.dm",
        "ship_damage_system.dm",
        "ship_default_stats.dm",
        "examples.dm"
    ]
    
    print("Обновление дефайнов в файлах системы боя...")
    print("=" * 60)
    
    updated_count = 0
    for filename in files_to_update:
        filepath = os.path.join(combat_dir, filename)
        if os.path.exists(filepath):
            if update_file(filepath):
                updated_count += 1
        else:
            print(f"✗ Файл не найден: {filepath}")
    
    print("=" * 60)
    print(f"Готово! Обновлено файлов: {updated_count}")

if __name__ == "__main__":
    main()
