local IncId = 0

XGlobalVar = {
    ScrollViewScrollDir = {
        ScrollDown = "ScrollDown", --从上往下滚
        ScrollRight = "ScrollRight" --从左往右滚
    },

    UiDesignSize = {    --ui设计尺寸
        Width = 1920,
        Height = 1080,
    },

    GetIncId = function()
        IncId = IncId + 1
        return IncId
    end
}