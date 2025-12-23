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

            // We only care about building blocks and tool cupboards
            if (!isBuildingBlock && !isToolCupboard)
                return;

            // If ALL damage is decay -> leave vanilla
            if (decayDamage > 0f && Mathf.Approximately(decayDamage, totalDamage))
                return;

            BasePlayer attacker = info.InitiatorPlayer;

            // ─────────────────────────────────────────────
            // 1) TOOL CUPBOARD: only authorized players can damage it
            // ─────────────────────────────────────────────
            if (isToolCupboard)
            {
                var cupboard = entity as BuildingPrivlidge;

                // No player or not authorized -> block all except decay
                if (attacker == null || cupboard == null || !cupboard.IsAuthed(attacker))
                {
                    info.damageTypes.ScaleAll(0f);

                    if (decayDamage > 0f)
                        info.damageTypes.Add(DamageType.Decay, decayDamage);

                    return;
                }

                // Authorized player for that TC -> normal damage (do nothing)
                return;
            }

            // ─────────────────────────────────────────────
            // 2) BUILDING BLOCKS: protected by TC except for authorized players
            // ─────────────────────────────────────────────
            if (isBuildingBlock)
            {
                var block = entity as BuildingBlock;

                // EXCLUSION: allow twig-grade blocks to always receive damage (no protection).
                // This makes twig blocks behave as unprotected regardless of TC.
                if (block != null && block.grade == BuildingGrade.Enum.Twigs)
                    return;

                // Check if this block is under any TC
                BuildingPrivlidge priv = block?.GetBuildingPrivilege();

                // If no TC protecting it -> vanilla behaviour
                if (priv == null)
                    return;

                // There is a TC: if attacker is authorized -> normal damage
                if (attacker != null && priv.IsAuthed(attacker))
                    return;

                // Any other (not authorized / NPC / heli / no player):
                // block all damage except decay
                info.damageTypes.ScaleAll(0f);

                if (decayDamage > 0f)
                    info.damageTypes.Add(DamageType.Decay, decayDamage);

                return;
            }
        }
    }
}
