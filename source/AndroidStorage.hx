package;

#if sys
import sys.FileSystem;
import sys.io.File;
#end

#if android
import androidmanager.os.Environment;
import androidmanager.tools.PermissionUtils;
#end

/**
 * External storage used ONLY by the Chart Editor.
 *
 * Android:
 *   /storage/emulated/0/KadeshEngine/charts/
 *
 * This is intentionally NOT a mods system.
 */
class AndroidStorage
{
    public static var rootPath:String = "";
    public static var chartsPath:String = "";
    public static var available(default, null):Bool = false;

    public static function init():Bool
    {
        #if android
        try
        {
            rootPath = Environment.getExternalStorageDirectory() + "/KadeshEngine";
        }
        catch (e:Dynamic)
        {
            rootPath = "/storage/emulated/0/KadeshEngine";
        }
        #elseif mobile
        rootPath = "/storage/emulated/0/KadeshEngine";
        #else
        rootPath = "";
        #end

        if (rootPath == "")
        {
            available = false;
            return false;
        }

        chartsPath = rootPath + "/charts";

        try
        {
            if (!FileSystem.exists(rootPath))
                FileSystem.createDirectory(rootPath);

            if (!FileSystem.exists(chartsPath))
                FileSystem.createDirectory(chartsPath);

            available = FileSystem.exists(chartsPath);
            return available;
        }
        catch (e:Dynamic)
        {
            available = false;
            return false;
        }
    }

    #if android
    public static function requestWritePermission():Void
    {
        try
        {
            PermissionUtils.requestPermissions([
                "android.permission.WRITE_EXTERNAL_STORAGE"
            ]);
        }
        catch (e:Dynamic)
        {
            // Permission failure must never crash the game.
        }
    }
    #end

    static function cleanName(name:String):String
    {
        if (name == null || name.trim() == "")
            name = "chart";

        var result = name;
        result = StringTools.replace(result, "/", "_");
        result = StringTools.replace(result, "\\", "_");
        result = StringTools.replace(result, ":", "_");
        result = StringTools.replace(result, "*", "_");
        result = StringTools.replace(result, "?", "_");
        result = StringTools.replace(result, "\"", "_");
        result = StringTools.replace(result, "<", "_");
        result = StringTools.replace(result, ">", "_");
        result = StringTools.replace(result, "|", "_");

        return result;
    }

    public static function chartPath(song:String):String
    {
        if (!available)
            init();

        return chartsPath + "/" + cleanName(song) + ".json";
    }

    public static function writeChart(song:String, data:String):Bool
    {
        if (!init())
        {
            #if android
            requestWritePermission();
            #end
            return false;
        }

        try
        {
            File.saveContent(chartPath(song), data);
            return true;
        }
        catch (e:Dynamic)
        {
            available = false;

            #if android
            requestWritePermission();
            #end

            return false;
        }
    }

    public static function readChart(song:String):String
    {
        if (!init())
            return null;

        var path = chartPath(song);

        try
        {
            if (!FileSystem.exists(path))
                return null;

            return File.getContent(path);
        }
        catch (e:Dynamic)
        {
            return null;
        }
    }
}
