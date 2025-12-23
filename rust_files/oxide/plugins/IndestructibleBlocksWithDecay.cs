using System;
using Oxide.Core;
using UnityEngine;
using Rust; // Needed for DamageType and building privilidge helpers

namespace Oxide.Plugins
{
    [Info("Indestructible Blocks With Decay", "mi_senor_helper", "1.2.0")]
    [Description("TC-authorized players can destroy their own blocks and cupboard; others cannot damage TC-protected blocks or cupboard. Decay stays vanilla; doors/deployables stay vulnerable.")]
    public class IndestructibleBlocksWithDecay : RustPlugin
    {
        private void OnEntityTakeDamage(BaseCombatEntity entity, HitInfo info)
        {
            if (entity == null || info == null)
                return;

            if (info.damageTypes == null)
                return;

            float totalDamage = info.damageTypes.Total();
            if (totalDamage <= 0f)
                return;

            float decayDamage = info.damageTypes.Get(DamageType.Decay);

            bool isBuildingBlock = entity is BuildingBlock;
            bool isToolCupboard = entity is BuildingPrivlidge;

            // Solo nos importan bloques de construcción y TC
            if (!isBuildingBlock && !isToolCupboard)
                return;

            // Si TODO el daño es decay → dejamos vanilla
            if (decayDamage > 0f && Mathf.Approximately(decayDamage, totalDamage))
                return;

            BasePlayer attacker = info.InitiatorPlayer;

            // ─────────────────────────────────────────────
            // 1) TOOL CUPBOARD: sólo players autorizados pueden dañarlo
            // ─────────────────────────────────────────────
            if (isToolCupboard)
            {
                var cupboard = entity as BuildingPrivlidge;

                // Sin player o no autorizado → bloquear todo salvo decay
                if (attacker == null || cupboard == null || !cupboard.IsAuthed(attacker))
                {
                    info.damageTypes.ScaleAll(0f);

                    if (decayDamage > 0f)
                        info.damageTypes.Add(DamageType.Decay, decayDamage);

                    return;
                }

                // Player autorizado en ese TC → daño normal (no tocamos nada)
                return;
            }

            // ─────────────────────────────────────────────
            // 2) BUILDING BLOCKS: protegidos por TC salvo para autorizados
            // ─────────────────────────────────────────────
            if (isBuildingBlock)
            {
                var block = entity as BuildingBlock;

                // Miramos si este bloque está bajo algún TC
                BuildingPrivlidge priv = block?.GetBuildingPrivilege();

                // Si no hay TC que lo proteja → comportamiento vanilla
                if (priv == null)
                    return;

                // Hay TC: si el atacante es player autorizado → daño normal
                if (attacker != null && priv.IsAuthed(attacker))
                    return;

                // Cualquier otro (no autorizado / NPC / heli / sin player):
                // bloquear todo el daño salvo decay
                info.damageTypes.ScaleAll(0f);

                if (decayDamage > 0f)
                    info.damageTypes.Add(DamageType.Decay, decayDamage);

                return;
            }
        }
    }
}
