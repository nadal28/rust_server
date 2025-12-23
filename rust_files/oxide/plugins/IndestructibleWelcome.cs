using Oxide.Core;
using Oxide.Core.Plugins;
using Oxide.Core.Libraries; // required for Timer
using Oxide.Core.Libraries.Covalence;

namespace Oxide.Plugins
{
    [Info("IndestructibleWelcome", "mi señor", "1.0.2")]
    [Description("Broadcasts a fixed welcome message to global chat every 15 minutes.")]
    public class IndestructibleWelcome : CovalencePlugin
    {
        // 15 minutes in seconds (float required by timer.Every)
        private const float IntervalSeconds = 15f * 60f;
        // Message to broadcast
        private const string BroadcastMessageText = "Welcome to Indestructible Bases server. Only doors can be raided. Bunkers not allowed";

        // Store the timer so it can be destroyed on unload.
        private Timer broadcastTimer;

        // Called when the plugin is loaded/initialized
        private void Init()
        {
            // Schedule a repeating timer that runs every IntervalSeconds seconds.
            // Save the returned Timer so we can destroy it later.
            broadcastTimer = timer.Every(IntervalSeconds, BroadcastMessage);
        }

        // Broadcast the fixed message to all players via the global server broadcast.
        private void BroadcastMessage()
        {
            server.Broadcast(BroadcastMessageText);
        }

        // Clean up the timer when plugin is unloaded to avoid orphaned timers.
        private void Unload()
        {
            if (broadcastTimer != null)
            {
                broadcastTimer.Destroy();
                broadcastTimer = null;
            }
        }
    }
}
