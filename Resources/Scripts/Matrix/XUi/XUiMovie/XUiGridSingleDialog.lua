local stringUtf8Len = string.Utf8Len
local DefaultColor = CS.UnityEngine.Color.white

local XUiGridSingleDialog = XClass(nil, "XUiGridSingleDialog")

function XUiGridSingleDialog:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
end

function XUiGridSingleDialog:Refresh(dialogContent, color, duration, typeWriterCb)
    local txtWords = self.TxtWords
    local typeWriter = self.TypeWriter
    txtWords.text = dialogContent

    self.DialogContent = dialogContent

    if color then
        txtWords.color = XUiHelper.Hexcolor2Color(color)
    end

    if duration then
        typeWriter.Duration = duration ~= 0 and duration or stringUtf8Len(dialogContent) * XMovieConfigs.TYPE_WRITER_SPEED
        typeWriter:Play()
    end

    if typeWriterCb then
        typeWriter.CompletedHandle = typeWriterCb
    end
end

function XUiGridSingleDialog:Reset()
    local txtWords = self.TxtWords
    txtWords.text = ""
    txtWords.color = DefaultColor

    local typeWriter = self.TypeWriter
    typeWriter:Stop()
    typeWriter.CompletedHandle = nil
end

function XUiGridSingleDialog:StopTypeWriter()
    self.TypeWriter:Stop()
end

return XUiGridSingleDialog