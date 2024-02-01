local XGoldenMinerFaceEmojiDataEntity = require("XModule/XGoldenMiner/Data/Game/XGoldenMinerFaceEmojiDataEntity")

---@class XUiGoldenMinerFaceEmojiPanel : XUiNode
---@field _Control XGoldenMinerControl
local XUiGoldenMinerFaceEmojiPanel = XClass(XUiNode, "XUiGoldenMinerFaceEmojiPanel")

function XUiGoldenMinerFaceEmojiPanel:OnStart(game)
    ---@type XGoldenMinerGameControl
    self._Game = game
    self:_InitFaceEmoji()
end

--region Ui - Init
function XUiGoldenMinerFaceEmojiPanel:_InitFaceEmoji()
    self:PlayAnimation("PanelEmoticonDisable")
    ---@type XGoldenMinerFaceEmojiDataEntity
    self._FaceEmojiDataEntity = XGoldenMinerFaceEmojiDataEntity.New()
    self._FaceEmojiDataEntity:SetStatus(XEnumConst.GOLDEN_MINER.GAME_FACE_PLAY_STATUS.NONE)
    self._FaceEmojiDataEntity:SetPlayDuration(self._Control:GetClientFaceEmojiShowTime())
    self.RImgHate = XUiHelper.TryGetComponent(self.Transform, "RImgHate", "RawImage")
end
--endregion

--region Ui - EmojiAnim
function XUiGoldenMinerFaceEmojiPanel:RefreshFaceEmoji(time)
    -- 动画播放中跳过
    if self._FaceEmojiDataEntity:CheckIsAnim() then
        return
    end
    local bePlayFaceId = self._FaceEmojiDataEntity:GetBePlayFaceId()
    local hasCurFaceId = self._FaceEmojiDataEntity:CheckHasCurFaceId()
    -- 优先播放普通表情
    if bePlayFaceId then
        -- 播放
        if not hasCurFaceId then
            self:_PlayFaceAnim(bePlayFaceId)
            return
        end
        if not self._FaceEmojiDataEntity:CheckIsPlayFaceId(bePlayFaceId) then
            self:_StopFaceAnim()
            return
        end
        if self._FaceEmojiDataEntity:CheckIsPlaying() then   -- 播放中
            self._FaceEmojiDataEntity:RefreshCurPlayDuration(time)
        else    -- 结束
            self._FaceEmojiDataEntity:RemoveCurPlayFaceId()
            self:_StopFaceAnim()
        end
        return
    end

    -- 播放状态表情
    -- 切换
    local statusFaceId = self._FaceEmojiDataEntity:GetStatusFaceId()
    local beStatusFaceId = self._FaceEmojiDataEntity:GetBeStatusFaceId()
    if statusFaceId ~= beStatusFaceId then
        self._FaceEmojiDataEntity:SetStatusFaceId(beStatusFaceId)
    end
    if hasCurFaceId and (not self._FaceEmojiDataEntity:CheckIsPlayFaceId(statusFaceId) or not statusFaceId) then
        -- 结束状态表情
        self:_StopFaceAnim()
    elseif not hasCurFaceId then
        -- 播放状态表情
        self:_PlayFaceAnim(self._FaceEmojiDataEntity:GetStatusFaceId())
    end
end

function XUiGoldenMinerFaceEmojiPanel:_PlayFaceAnim(faceId)
    if not XTool.IsNumberValid(faceId) then
        return
    end
    self:Open()
    self._FaceEmojiDataEntity:SetCurFaceId(faceId)
    self._FaceEmojiDataEntity:SetCurPlayDuration(self._FaceEmojiDataEntity:GetPlayDuration())
    self._FaceEmojiDataEntity:SetIsAnim(true)

    local img = self._Control:GetCfgFaceImage(faceId)
    if not XTool.UObjIsNil(self.RImgHate) then
        self.RImgHate:SetRawImage(img)
    end

    XEventManager.DispatchEvent(XEventId.EVENT_GOLDEN_MINER_GAME_FACE_ANIM, true)
end

function XUiGoldenMinerFaceEmojiPanel:_StopFaceAnim()
    self._FaceEmojiDataEntity:SetCurFaceId(false)
    self._FaceEmojiDataEntity:SetIsAnim(true)
    XEventManager.DispatchEvent(XEventId.EVENT_GOLDEN_MINER_GAME_FACE_ANIM, false)
end

function XUiGoldenMinerFaceEmojiPanel:SetIsAfterAnim()
    self._FaceEmojiDataEntity:SetIsAnim(false)
end
--endregion

--region Ui - PlayEmoji
---@param type number XEnumConst.GOLDEN_MINER.GAME_FACE_PLAY_TYPE
function XUiGoldenMinerFaceEmojiPanel:PlayFaceEmoji(type, faceId)
    if not XTool.IsNumberValid(faceId) or not self._Game.SystemHook then
        return
    end

    if type == XEnumConst.GOLDEN_MINER.GAME_FACE_PLAY_TYPE.NONE then
        self:_UpdateFaceEmojiByNone()
    elseif type == XEnumConst.GOLDEN_MINER.GAME_FACE_PLAY_TYPE.SHOOTING then
        self:_UpdateFaceEmojiByShooting(faceId)
    elseif type == XEnumConst.GOLDEN_MINER.GAME_FACE_PLAY_TYPE.GRAB_STONE then
        self:_UpdateFaceEmojiByGrabStone(faceId)
    elseif type == XEnumConst.GOLDEN_MINER.GAME_FACE_PLAY_TYPE.GRAB_NONE then
        self:_UpdateFaceEmojiByGrabNone(faceId)
    elseif type == XEnumConst.GOLDEN_MINER.GAME_FACE_PLAY_TYPE.REVOKING then
        self:_UpdateFaceEmojiByRevoking(faceId)
    elseif type == XEnumConst.GOLDEN_MINER.GAME_FACE_PLAY_TYPE.GRABBED then
        self:_UpdateFaceEmojiByGrabbed(faceId)
    elseif type == XEnumConst.GOLDEN_MINER.GAME_FACE_PLAY_TYPE.USE_ITEM then
        self:_UpdateFaceEmojiByUseItem(faceId)
    elseif type == XEnumConst.GOLDEN_MINER.GAME_FACE_PLAY_TYPE.USE_BY_WEIGHT then
        self:_UpdateFaceEmojiByUseItemWithWight(faceId)
    elseif type == XEnumConst.GOLDEN_MINER.GAME_FACE_PLAY_TYPE.USE_BY_SCORE then
        self:_UpdateFaceEmojiByUseItemWithScore(faceId)
    elseif type == XEnumConst.GOLDEN_MINER.GAME_FACE_PLAY_TYPE.PLAY_BY_SCORE then
        self:_UpdateFaceEmojiByPlayScore(faceId)
    end
end

function XUiGoldenMinerFaceEmojiPanel:PlayFaceEmojiByUseItem(itemId)
    local buffId = self._Control:GetCfgItemBuffId(itemId)
    local type = self._Control:GetCfgBuffType(buffId)
    local faceId = self._Control:GetCfgItemUseFaceId(itemId)
    if type == XEnumConst.GOLDEN_MINER.BUFF_TYPE.STONE_CHANGE_GOLD
            or type == XEnumConst.GOLDEN_MINER.BUFF_TYPE.BOOM
    then
        self:PlayFaceEmoji(XEnumConst.GOLDEN_MINER.GAME_FACE_PLAY_TYPE.USE_BY_SCORE, faceId)
        return
    end
    self:PlayFaceEmoji(XEnumConst.GOLDEN_MINER.GAME_FACE_PLAY_TYPE.USE_ITEM, faceId)
end

function XUiGoldenMinerFaceEmojiPanel:_GetFaceIdByGroupIdByWeight(faceId, stoneStatus)
    if not XTool.IsNumberValid(faceId) then
        return faceId
    end
    local faceGroupId = self._Control:GetCfgFaceGroup(faceId)
    if not XTool.IsNumberValid(faceGroupId) then
        return faceId
    end
    local weight = self._Game.SystemHook:GetHookGrabbingWeight(stoneStatus)
    return self._Control:GetFaceIdByGroup(faceGroupId, weight)
end

function XUiGoldenMinerFaceEmojiPanel:_GetFaceIdByGroupIdByScore(faceId, stoneStatus)
    if not XTool.IsNumberValid(faceId) then
        return faceId
    end
    local faceGroupId = self._Control:GetCfgFaceGroup(faceId)
    if not XTool.IsNumberValid(faceGroupId) then
        return faceId
    end
    local score = self._Game.SystemHook:GetHookGrabbingScore(stoneStatus)
    return self._Control:GetFaceIdByGroup(faceGroupId, score)
end
--endregion

--region Data - PlayEmoji
function XUiGoldenMinerFaceEmojiPanel:_UpdateFaceEmojiByNone()
    self._FaceEmojiDataEntity:SetStatus(XEnumConst.GOLDEN_MINER.GAME_FACE_PLAY_STATUS.NONE)
end

function XUiGoldenMinerFaceEmojiPanel:_UpdateFaceEmojiByShooting(faceId)
    self._FaceEmojiDataEntity:SetStatus(XEnumConst.GOLDEN_MINER.GAME_FACE_PLAY_STATUS.SHOOTING)
    self._FaceEmojiDataEntity:SetBeStatusFaceId(faceId)
end

function XUiGoldenMinerFaceEmojiPanel:_UpdateFaceEmojiByGrabStone(faceId)
    self._FaceEmojiDataEntity:SetStatus(XEnumConst.GOLDEN_MINER.GAME_FACE_PLAY_STATUS.NONE)
    self._FaceEmojiDataEntity:AddPlayFaceId(faceId)
end

function XUiGoldenMinerFaceEmojiPanel:_UpdateFaceEmojiByGrabNone(faceId)
    self._FaceEmojiDataEntity:SetStatus(XEnumConst.GOLDEN_MINER.GAME_FACE_PLAY_STATUS.NONE)
    self._FaceEmojiDataEntity:AddPlayFaceId(faceId)
end

function XUiGoldenMinerFaceEmojiPanel:_UpdateFaceEmojiByRevoking(faceId)
    self._FaceEmojiDataEntity:SetStatus(XEnumConst.GOLDEN_MINER.GAME_FACE_PLAY_STATUS.REVOKING)

    local stoneEntityUidList = self._Game.SystemHook:GetAllHookGrabbingEntityUidList(XEnumConst.GOLDEN_MINER.GAME_STONE_STATUS.GRABBING)
    if XTool.IsTableEmpty(stoneEntityUidList) then
        return
    end
    -- 拉回根据重量
    faceId = self:_GetFaceIdByGroupIdByWeight(faceId, XEnumConst.GOLDEN_MINER.GAME_STONE_STATUS.GRABBING)
    self._FaceEmojiDataEntity:SetBeStatusFaceId(faceId)
end

function XUiGoldenMinerFaceEmojiPanel:_UpdateFaceEmojiByGrabbed(faceId)
    self._FaceEmojiDataEntity:SetStatus(XEnumConst.GOLDEN_MINER.GAME_FACE_PLAY_STATUS.NONE)

    -- 当抓取物为1时，抓到特殊物品时
    local stoneEntityUidList = self._Game.SystemHook:GetAllHookGrabbingEntityUidList(XEnumConst.GOLDEN_MINER.GAME_STONE_STATUS.GRABBED)
    if #stoneEntityUidList == 1 then
        local stoneEntity = self._Game:GetStoneEntityByUid(stoneEntityUidList[1])
        local stoneGrabFaceId = self._Control:GetCfgStoneTypeGrabFaceId(stoneEntity.Data:GetType())
        if XTool.IsNumberValid(stoneGrabFaceId) then
            self._FaceEmojiDataEntity:AddPlayFaceId(stoneGrabFaceId)
            return
        end
    end
    -- 非特殊物品和抓取物为复数时
    faceId = self:_GetFaceIdByGroupIdByScore(faceId, XEnumConst.GOLDEN_MINER.GAME_STONE_STATUS.GRABBED)
    self._FaceEmojiDataEntity:AddPlayFaceId(faceId)
end

function XUiGoldenMinerFaceEmojiPanel:_UpdateFaceEmojiByUseItem(faceId)
    self._FaceEmojiDataEntity:AddPlayFaceId(faceId)
end

function XUiGoldenMinerFaceEmojiPanel:_UpdateFaceEmojiByUseItemWithWight(faceId)
    self._FaceEmojiDataEntity:AddPlayFaceId(faceId)
    local secondFaceId = self:_GetFaceIdByGroupIdByWeight(faceId, XEnumConst.GOLDEN_MINER.GAME_STONE_STATUS.GRABBING)
    if faceId ~= secondFaceId then
        self._FaceEmojiDataEntity:AddPlayFaceId(secondFaceId)
    end
end

function XUiGoldenMinerFaceEmojiPanel:_UpdateFaceEmojiByUseItemWithScore(faceId)
    self._FaceEmojiDataEntity:AddPlayFaceId(faceId)
    -- 使用需要根据价值区分表情的道具
    local secondFaceId = self:_GetFaceIdByGroupIdByScore(faceId, XEnumConst.GOLDEN_MINER.GAME_STONE_STATUS.GRABBING)
    if faceId ~= secondFaceId then
        self._FaceEmojiDataEntity:AddPlayFaceId(secondFaceId)
    end
end

function XUiGoldenMinerFaceEmojiPanel:_UpdateFaceEmojiByPlayScore(faceId)
    self._FaceEmojiDataEntity:SetStatus(XEnumConst.GOLDEN_MINER.GAME_FACE_PLAY_STATUS.NONE)
    self._FaceEmojiDataEntity:AddPlayFaceId(faceId)
end
--endregion

return XUiGoldenMinerFaceEmojiPanel