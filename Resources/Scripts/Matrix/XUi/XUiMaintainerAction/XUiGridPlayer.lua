local XUiGridPlayer = XClass(nil, "XUiGridPlayer")

local TweenSpeed = 0.3

function XUiGridPlayer:Ctor(ui,base)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.Base = base
    self.IsPlayerIn = false
    self.CurInNodeId = 1
    self.CurOutNodeId = 1
    self.CurState = XMaintainerActionConfigs.NodeState.Normal
    XTool.InitUiObject(self)
    self:SetButtonCallBack()
end

function XUiGridPlayer:SetButtonCallBack()

end

function XUiGridPlayer:OnBtnIatticeClick()

end

function XUiGridPlayer:SetPlayerData(entity)
    self.PlayerEntity = entity
    if entity then
        local startNode = self.Base.NodeList[entity:GetPosNodeId()]
        self.CurNodeText.text = startNode.NoteEntity:GetName()
        self.Transform.position = startNode.Transform.position
        XUiPLayerHead.InitPortrait(entity:GetHeadPortraitId(), entity:GetHeadFrameId(), self.Head)
        self.CurOutNodeId = entity:GetPosNodeId()
        self.CurInNodeId = entity:GetPosNodeId()
        self.Base.NodeList[self.CurOutNodeId]:PlayerInShow(true, false)
        self.Description.gameObject:SetActiveEx(true)
    end
end

function XUiGridPlayer:Move(routeIdList, cb)
    if not routeIdList then return end
    local tagId = routeIdList[1]
    local lastId = routeIdList[#routeIdList]

    local tagPos = tagId and self.Base.NodeList[tagId].Transform.position
    if tagPos and lastId then
        local CurPosId = self.PlayerEntity:GetPosNodeId()
        self.PlayerEntity:MoveTo(lastId)
        self.PlayerEntity:UnMarkNodeEvent()
        self.CurInNodeId = tagId
        
        self.Base.NodeList[self.CurOutNodeId]:PlayerInShow(false, true)
        self.Base.NodeList[self.CurInNodeId]:PlayerInShow(true, true)
        self.Base.NodeList[self.CurOutNodeId]:SetNodeState(XMaintainerActionConfigs.NodeState.Normal)
        
        self.Description.gameObject:SetActiveEx(false)
        XLuaUiManager.SetMask(true)
        self.PlayerMoveTimer = XUiHelper.DoWorldMove(self.Transform, tagPos, TweenSpeed, XUiHelper.EaseType.Linear, function ()
                XLuaUiManager.SetMask(false)
                self.PlayerMoveTimer = nil
                self.Base.NodeList[self.CurInNodeId]:SetNodeState(XMaintainerActionConfigs.NodeState.Normal)
                self.CurOutNodeId = tagId
                local nextRoute = routeIdList
                table.remove(nextRoute,1)
                self:Move(nextRoute, cb)
            end)
    else
        self:SetCurNodeNameTag()
        self.Description.gameObject:SetActiveEx(true)
        if cb then cb() end
    end
end

function XUiGridPlayer:SetCurNodeNameTag()
    self.CurNodeText.text = self.Base.NodeList[self.CurInNodeId].NoteEntity:GetName()
end

function XUiGridPlayer:DoChangeDirection()
    self.PlayerEntity:DoChangeDirection()
end

function XUiGridPlayer:StopTween()
    if self.PlayerMoveTimer then
        XScheduleManager.UnSchedule(self.PlayerMoveTimer)
        self.PlayerMoveTimer = nil
        XLuaUiManager.SetMask(false)
    end
end

return XUiGridPlayer