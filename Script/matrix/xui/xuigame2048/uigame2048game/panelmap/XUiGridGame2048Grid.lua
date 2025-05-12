---@class XUiGridGame2048Grid: XUiNode
---@field _Control XGame2048Control
---@field _GameControl XGame2048GameControl
---@field ShakeTweener DG.Tweening.Tweener
local XUiGridGame2048Grid = XClass(XUiNode, 'XUiGridGame2048Grid')
local XUiComGame2048GridAction = require('XUi/XUiGame2048/UiGame2048Game/PanelMap/XUiComGame2048GridAction')

local FeverAddMax = nil

function XUiGridGame2048Grid:OnStart()
    ---@type XUiComGame2048GridAction
    self.ActionCom = XUiComGame2048GridAction.New(self.GameObject, self)

    if XMain.IsEditorDebug then
        -- debug模式下方便配置表重载，每次加载都读
        FeverAddMax = self._Control:GetClientConfigNum('GridFeverAddMax')
    elseif not FeverAddMax then
        FeverAddMax = self._Control:GetClientConfigNum('GridFeverAddMax')
    end
end

---@param data XGame2048Grid
function XUiGridGame2048Grid:RefreshData(data)
    self.Id = data.Id
    self.Uid = data.Uid

    if data:GetGridType() == XMVCA.XGame2048.EnumConst.GridType.FeverTurnAdds then    
        -- 显示加时方块的加时数
        if self.GridPoint and self.GridPoint.text then
            self.GridPoint.gameObject:SetActiveEx(true)
            self.GridPoint.text = data:GetExValue()
        end
    end

    if self.TxtNum then
        self.TxtNum.gameObject:SetActiveEx(true)
        self.TxtNum.text = data:GetValue()
    end

    ---@type XTableGame2048Block
    local blockCfg = self._Control:GetBlockCfgById(self.Id)

    if self.Image then
        self.Image.gameObject:SetActiveEx(true)
        if blockCfg then
            if not string.IsNilOrEmpty(blockCfg.BgRes) then
                self.Image:SetRawImage(blockCfg.BgRes)
            end
        end
    end

    if self.ImgIcon then
        local hasIcon = not string.IsNilOrEmpty(blockCfg.IconRes)
        
        self.ImgIcon.gameObject:SetActiveEx(hasIcon)

        if hasIcon then
            self.ImgIcon:SetRawImage(blockCfg.IconRes)
        end
    end
end

function XUiGridGame2048Grid:SetShow(blockId)
    ---@type XTableGame2048Block
    local cfg = self._Control:GetBlockCfgById(blockId)

    if cfg then
        if self.TxtNum then
            if cfg.Type == XMVCA.XGame2048.EnumConst.GridType.Rock then
                self.TxtNum.text = cfg.HitTimes
            else
                self.TxtNum.text = cfg.Level
            end
        end

        if self.Image then
            if not string.IsNilOrEmpty(cfg.BgRes) then
                self.Image:SetRawImage(cfg.BgRes)
            end
        end
    end
end

function XUiGridGame2048Grid:SetNormalizePos(x, y)
    self.X = x
    self.Y = y

    if XMain.IsEditorDebug then
        self.GameObject.name = 'Grid'..tostring(self.Id).."_"..tostring(self.X)..","..tostring(self.Y)
    end
end

function XUiGridGame2048Grid:SetGridType(type)
    self._GridType = type

    self.ActionCom:UpdateConfigParams(type)
end

function XUiGridGame2048Grid:GetGridType()
    return self._GridType
end

return XUiGridGame2048Grid