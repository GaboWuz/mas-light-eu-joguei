package;

import StringTools;
import haxe.io.Path;

using StringTools;

#if sys
import sys.FileSystem;
import sys.io.File;
#end

#if android
import androidmanager.content.Interface;
import androidmanager.os.Environment;
import androidmanager.os.Build.VERSION;
import androidmanager.tools.PermissionUtils;
#end

/**
 * External storage used by Kade/Kade mobile.
 *
 * Root: /storage/emulated/0/KadeEngine
 * Charts: KadeEngine/mods/data/<song>/<song>.json
 *
 * The storage is optional: failure never prevents the game from starting.
 */
class AndroidStorage
{
    public static inline var APP_FOLDER:String = "KadeEngine";

    public static var root(default, null):String = "";
    public static var mods(default, null):String = "";
    public static var available(default, null):Bool = false;
    public static var initialized(default, null):Bool = false;
    public static var lastError(default, null):String = "";

    static var silentProbeDone:Bool = false;
    static var permissionFlowStarted:Bool = false;
    static var allFilesSettingsOpened:Bool = false;
    static var warningShown:Bool = false;

    public static function init():Void
    {
        if (available || silentProbeDone)
            return;

        silentProbeDone = true;
        tryInitialize();
    }

    public static function startPermissionFlow():Void
    {
        if (available || tryInitialize())
            return;

        #if android
        if (permissionFlowStarted)
            return;

        permissionFlowStarted = true;

        if (VERSION.SDK_INT >= 30)
        {
            requestAllFilesOrWarn();
            return;
        }

        if (VERSION.SDK_INT >= 23 && !PermissionUtils.hasPermission("WRITE_EXTERNAL_STORAGE"))
        {
            try
            {
                PermissionUtils.requestPermissions([
                    "READ_EXTERNAL_STORAGE",
                    "WRITE_EXTERNAL_STORAGE"
                ]);
            }
            catch (e:Dynamic)
            {
                lastError = Std.string(e);
                trace('[AndroidStorage] permission request failed: ' + lastError);
            }

            haxe.Timer.delay(function():Void
            {
                if (!available && PermissionUtils.hasPermission("WRITE_EXTERNAL_STORAGE"))
                    tryInitialize();
            }, 1500);
            return;
        }

        requestAllFilesOrWarn();
        #else
        warnOnce("External storage is only available on Android.");
        #end
    }

    #if android
    public static function onAppActivate():Void
    {
        if (available || !permissionFlowStarted)
            return;

        if (tryInitialize())
            return;

        if (VERSION.SDK_INT >= 30 && !Environment.isExternalStorageManager())
        {
            if (allFilesSettingsOpened)
                warnOnce("Storage permission was not granted. External charts are disabled.");
            else
                requestAllFilesAccess();
        }
        else
        {
            warnOnce("Could not access /storage/emulated/0/" + APP_FOLDER + ".");
        }
    }
    #else
    public static function onAppActivate():Void {}
    #end

    static function tryInitialize():Bool
    {
        #if sys
        try
        {
            setup(buildRoot());

            var probe = join(root, ".Kade_write_test");
            File.saveContent(probe, "ok");
            if (FileSystem.exists(probe))
                FileSystem.deleteFile(probe);

            available = true;
            initialized = true;
            lastError = "";
            trace('[AndroidStorage] ready: ' + root);
            return true;
        }
        catch (e:Dynamic)
        {
            available = false;
            initialized = false;
            lastError = Std.string(e);
            trace('[AndroidStorage] unavailable: ' + lastError);
            return false;
        }
        #else
        return false;
        #end
    }

    static function buildRoot():String
    {
        #if android
        var base:Null<String> = Environment.getExternalStorageDirectory();
        if (base == null || base.length == 0 || base == "Unknown" || base.startsWith("Error:"))
            throw "Android did not return shared storage path.";
        return join(base, APP_FOLDER);
        #elseif sys
        return Path.join([Sys.getCwd(), APP_FOLDER]);
        #else
        return APP_FOLDER;
        #end
    }

    #if android
    static function requestAllFilesOrWarn():Void
    {
        if (available || tryInitialize())
            return;

        if (VERSION.SDK_INT >= 30 && !Environment.isExternalStorageManager())
            requestAllFilesAccess();
        else
            warnOnce("Could not access /storage/emulated/0/" + APP_FOLDER + ". External charts are disabled.");
    }

    static function requestAllFilesAccess():Void
    {
        if (allFilesSettingsOpened)
            return;

        try
        {
            Interface.showConfirm(
                "External storage permission",
                "Allow the game to manage files to use /storage/emulated/0/" + APP_FOLDER +
                ".\n\nIf you deny it, the game will continue normally without external charts.",
                "Open settings",
                "Continue without it",
                function():Void
                {
                    allFilesSettingsOpened = true;
                    try
                    {
                        Interface.requestSetting("MANAGE_APP_ALL_FILES_ACCESS_PERMISSION", 7701);
                    }
                    catch (e:Dynamic)
                    {
                        lastError = Std.string(e);
                        warnOnce(lastError);
                    }
                },
                function():Void
                {
                    warnOnce("Storage permission was not granted. External charts are disabled.");
                }
            );
        }
        catch (e:Dynamic)
        {
            lastError = Std.string(e);
            warnOnce(lastError);
        }
    }
    #end

    #if sys
    static function setup(baseRoot:String):Void
    {
        root = normalize(baseRoot);
        mods = join(root, "mods");
        ensureDir(root);
        ensureDir(mods);
        ensureDir(join(mods, "data"));
        ensureDir(join(mods, "songs"));
        ensureDir(join(mods, "images"));
        ensureDir(join(mods, "sounds"));
        ensureDir(join(mods, "characters"));
        ensureDir(join(mods, "stages"));
        ensureDir(join(mods, "scripts"));
        ensureDir(join(mods, "custom_events"));
        ensureDir(join(mods, "custom_notetypes"));
    }
    #end

    public static function modPath(relative:String):String
    {
        init();
        if (!available || mods.length == 0)
            return "__Kade_MODS_DISABLED__/" + cleanRelative(relative);
        return join(mods, cleanRelative(relative));
    }

    public static function modExists(relative:String):Bool
    {
        #if sys
        if (!available)
            return false;

        try
        {
            var path = modPath(relative);
            return FileSystem.exists(path) && !FileSystem.isDirectory(path);
        }
        catch (e:Dynamic) {}
        #end
        return false;
    }

    public static function readText(relative:String, ?fallback:String = null):String
    {
        #if sys
        if (!available)
            return fallback;

        try
        {
            var path = modPath(relative);
            if (FileSystem.exists(path) && !FileSystem.isDirectory(path))
                return File.getContent(path);
        }
        catch (e:Dynamic)
        {
            trace('[AndroidStorage] read failed: ' + Std.string(e));
        }
        #end
        return fallback;
    }

    public static function writeText(relative:String, content:String):Bool
    {
        #if sys
        if (!available)
            return false;

        try
        {
            var path = modPath(relative);
            var parent = Path.directory(path);
            if (parent != null && parent.length > 0)
                ensureDir(parent);
            File.saveContent(path, content);
            return true;
        }
        catch (e:Dynamic)
        {
            trace('[AndroidStorage] write failed: ' + Std.string(e));
        }
        #end
        return false;
    }

    public static function chartPath(song:String):String
    {
        var clean = cleanRelative(song == null ? "" : song.toLowerCase());
        return "data/" + clean + "/" + clean + ".json";
    }

    public static function writeChart(song:String, content:String):Bool
    {
        return writeText(chartPath(song), content);
    }

    public static function readChart(song:String):String
    {
        return readText(chartPath(song), null);
    }

    static function warnOnce(message:String):Void
    {
        if (warningShown)
            return;
        warningShown = true;
        trace('[AndroidStorage] ' + message);

        #if android
        try
        {
            Interface.showAlert("External storage disabled", message + "\n\nThe game will continue using internal files.", "Continue");
        }
        catch (e:Dynamic) {}
        #end
    }

    static function cleanRelative(path:String):String
    {
        if (path == null)
            return "";
        var result = StringTools.replace(path, "\\", "/");
        while (result.startsWith("/"))
            result = result.substr(1);
        while (result.indexOf("../") != -1)
            result = StringTools.replace(result, "../", "");
        return result;
    }

    static function normalize(path:String):String
    {
        if (path == null)
            return "";
        return StringTools.replace(path, "\\", "/");
    }

    static function join(left:String, right:String):String
    {
        if (left == null || left.length == 0)
            return cleanRelative(right);
        if (right == null || right.length == 0)
            return normalize(left);

        var cleanLeft = normalize(left);
        while (cleanLeft.endsWith("/"))
            cleanLeft = cleanLeft.substr(0, cleanLeft.length - 1);
        return cleanLeft + "/" + cleanRelative(right);
    }

    #if sys
    static function ensureDir(directory:String):Void
    {
        if (directory == null || directory.length == 0 || FileSystem.exists(directory))
            return;

        var parent = Path.directory(directory);
        if (parent != null && parent.length > 0 && parent != directory)
            ensureDir(parent);

        if (!FileSystem.exists(directory))
            FileSystem.createDirectory(directory);
    }
    #end
}
