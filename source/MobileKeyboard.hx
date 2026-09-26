package;

#if mobile
import flixel.FlxG;
import lime.ui.KeyCode;
import lime.ui.KeyModifier;
import lime.ui.Window;
#end

/**
 * Native mobile text input used by ChartingState.
 *
 * The Flixel input remains the visible editor field (typingShit).
 * Lime's window text input is only used to ask Android/iOS for the
 * software keyboard; the typed text is forwarded to a callback so it
 * can be written back into the same field.
 */
class MobileKeyboard
{
    #if mobile
    private var window:Window;
    private var text:String = "";
    private var onTextChange:String->Void;
    private var opened:Bool = false;

    public function new()
    {
        if (FlxG.stage != null)
            window = FlxG.stage.window;
    }

    /**
     * Requests the Android/iOS software keyboard.
     *
     * initialText = current text from ChartingState.typingShit
     * callback    = writes the changed text back into typingShit
     */
    public function open(initialText:String, callback:String->Void):Void
    {
        if (window == null)
            return;

        onTextChange = callback;
        text = initialText == null ? "" : initialText;

        if (!opened)
        {
            window.onTextInput.add(onNativeTextInput);
            window.onKeyDown.add(onNativeKeyDown);
        }

        opened = true;
        window.textInputEnabled = true;
    }

    private function onNativeTextInput(value:String):Void
    {
        if (!opened || value == null || value == "")
            return;

        text += value;
        notify();
    }

    private function onNativeKeyDown(keyCode:KeyCode, modifier:KeyModifier):Void
    {
        if (!opened)
            return;

        switch (keyCode)
        {
            case KeyCode.BACKSPACE, KeyCode.NUMPAD_BACKSPACE:
                if (text.length > 0)
                {
                    text = text.substr(0, text.length - 1);
                    notify();
                }
            case KeyCode.RETURN, KeyCode.NUMPAD_ENTER:
                close();
            default:
        }
    }

    private function notify():Void
    {
        if (onTextChange != null)
            onTextChange(text);
    }

    /** Hide the software keyboard and stop listening for input. */
    public function close():Void
    {
        if (window == null || !opened)
            return;

        opened = false;
        onTextChange = null;

        window.onTextInput.remove(onNativeTextInput);
        window.onKeyDown.remove(onNativeKeyDown);
        window.textInputEnabled = false;
    }

    public function isOpen():Bool
    {
        return opened;
    }

    public function destroy():Void
    {
        close();
        window = null;
    }
    #end
}
