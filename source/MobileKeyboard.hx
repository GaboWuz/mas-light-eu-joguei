package;

#if mobile
import openfl.Lib;
import openfl.events.Event;
import openfl.geom.Rectangle;
import openfl.text.StageText;
#end

/**
 * Native mobile text input used by ChartingState.
 *
 * The Flixel input remains the visible editor field (typingShit).
 * StageText is only used to give Android/iOS a real native text input
 * so the software keyboard can be opened and physical keyboards can
 * also type into the same field.
 */
class MobileKeyboard
{
    #if mobile
    private var nativeInput:StageText;
    private var onTextChange:String->Void;
    private var opened:Bool = false;

    public function new()
    {
        nativeInput = new StageText();
        nativeInput.addEventListener(Event.CHANGE, onNativeChange);
        nativeInput.visible = false;
    }

    /**
     * Opens the native text input and requests the Android/iOS keyboard.
     *
     * initialText = current text from ChartingState.typingShit
     * callback    = writes the changed text back into typingShit
     */
    public function open(initialText:String, callback:String->Void):Void
    {
        onTextChange = callback;

        nativeInput.text = initialText == null ? "" : initialText;

        // Small native input placed over the chart-name field.
        // StageText uses stage coordinates, not Flixel camera coordinates.
        nativeInput.viewPort = new Rectangle(10, 10, 220, 42);

        if (Lib.current != null && Lib.current.stage != null)
            nativeInput.stage = Lib.current.stage;

        nativeInput.visible = true;
        opened = true;

        // Requests focus from the native platform.
        // Android should open the software keyboard here.
        nativeInput.assignFocus();
    }

    private function onNativeChange(event:Event):Void
    {
        if (!opened || onTextChange == null)
            return;

        onTextChange(nativeInput.text == null ? "" : nativeInput.text);
    }

    /** Close the native input and release focus. */
    public function close():Void
    {
        if (nativeInput == null)
            return;

        opened = false;
        onTextChange = null;
        nativeInput.visible = false;
    }

    public function isOpen():Bool
    {
        return opened;
    }

    public function destroy():Void
    {
        if (nativeInput == null)
            return;

        close();
        nativeInput.removeEventListener(Event.CHANGE, onNativeChange);

        try
        {
            nativeInput.stage = null;
        }
        catch (e:Dynamic)
        {
            // Some OpenFL versions do not allow clearing StageText.stage.
            // Nothing else is required for cleanup.
        }

        nativeInput = null;
    }
    #end
}
