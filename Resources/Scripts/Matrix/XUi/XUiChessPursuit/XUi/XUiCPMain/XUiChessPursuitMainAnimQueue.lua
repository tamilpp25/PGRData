local XUiChessPursuitMainAnimQueue = XClass(nil, "XUiChessPursuitMainAnimQueue")

--动画的播放队列
function XUiChessPursuitMainAnimQueue:Ctor(rootUi)
    self.RootUi = rootUi

    self.AnimationList = {}
    self.IsPlay = false
end

function XUiChessPursuitMainAnimQueue:Push(aniName, beginCallBack, finishCallBack)
    table.insert(self.AnimationList, {
        aniName = aniName,
        BeginCallBack = beginCallBack,
        FinishCallBack = finishCallBack,
    })
end

function XUiChessPursuitMainAnimQueue:Pop()
    local animationList = self.AnimationList[1]

    if not animationList then
        return
    end

    table.remove(self.AnimationList, 1)
end

function XUiChessPursuitMainAnimQueue:PopAndPlay()
    if self.IsPlay then
        return
    end

    if not self.RootUi.GameObject.activeSelf then
        local animationList = self.AnimationList[1]

        if animationList.BeginCallBack then
            animationList.BeginCallBack()
        end

        self:Pop()
        
        if animationList.FinishCallBack then
            animationList.FinishCallBack()
        end
        return
    end

    if next(self.AnimationList) then
        local animationList = self.AnimationList[1]

        self.IsPlay = true
        
        if animationList.BeginCallBack then
            animationList.BeginCallBack()
        end

        self.RootUi:PlayAnimationWithMask(animationList.aniName, function ()
            self.IsPlay = false
            self:Pop()
            if animationList.FinishCallBack then
                animationList.FinishCallBack()
            end
        end)
    end
end

function XUiChessPursuitMainAnimQueue:Clear()
    self.AnimationList = {}
end

function XUiChessPursuitMainAnimQueue:GetCount()
    return #self.AnimationList
end

return XUiChessPursuitMainAnimQueue
