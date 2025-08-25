import {
  Box,
  Container,
  Typography,
  Card,
  CardContent,
  Grid,
  Button,
  Alert,
  IconButton,
  Paper,
  useTheme,
  TextField,
  CircularProgress,
  Autocomplete,
  Chip,
} from "@mui/material";
import {
  ContentCopy as CopyIcon,
  Save as SaveIcon,
  CloudDownload as CloudDownloadIcon,
  Refresh as RefreshIcon,
  Settings as SettingsIcon,
  AutoMode as AutoModeIcon,
  ToggleOn as ToggleOnIcon,
  ToggleOff as ToggleOffIcon,
} from "@mui/icons-material";
import { useAuth, fetchWithAuth } from "../hooks/useAuth";
import { useEffect, useState } from "react";
import { z } from "zod";
import {
  ProviderConfigSchema,
  UserConfigSchema,
  ModelMappingConfigSchema,
  UserModelConfigSchema,
  UpdateUserConfigSchema,
} from "../../../common/validators/config.schema";
import {
  PRESET_API_PROVIDERS,
  FIXED_MODEL_RULES,
  DEFAULT_MAPPING_CONFIG,
} from "../../../src/config/defaultModelMappings";

type ProviderData = z.infer<typeof ProviderConfigSchema>;
type ModelMappingConfig = z.infer<typeof ModelMappingConfigSchema>;
type UserModelConfig = z.infer<typeof UserModelConfigSchema>;

export function DashboardPage() {
  const theme = useTheme();
  const { user, isAuthenticated, isLoading: isAuthLoading } = useAuth();

  // 简单的表单状态
  const [baseUrl, setBaseUrl] = useState("https://api.nekro.ai/v1");
  const [apiKey, setApiKey] = useState("");
  const [useSystemMapping, setUseSystemMapping] = useState(true);
  const [customModels, setCustomModels] = useState<Record<string, string>>({});

  const [models, setModels] = useState<{ id: string; name: string }[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [isFetchingModels, setIsFetchingModels] = useState(false);
  const [isSaving, setIsSaving] = useState(false);

  // 添加错误状态管理
  const [modelFetchError, setModelFetchError] = useState<string | null>(null);
  const [lastFetchAttempt, setLastFetchAttempt] = useState<Date | null>(null);

  // 添加保存状态管理
  const [saveStatus, setSaveStatus] = useState<{ type: "success" | "error" | null; message: string | null }>({
    type: null,
    message: null,
  });

  // 添加配置加载状态管理
  const [configLoadError, setConfigLoadError] = useState<string | null>(null);

  // 加载配置
  useEffect(() => {
    if (!isAuthenticated || isAuthLoading) return;

    setConfigLoadError(null); // 清除之前的错误

    fetchWithAuth("/api/config")
      .then((res) => {
        if (!res.ok) {
          throw new Error(`加载配置失败 (HTTP ${res.status})`);
        }
        return res.json();
      })
      .then((data: any) => {
        setBaseUrl(data.provider.baseUrl || "https://api.nekro.ai/v1");
        setApiKey(data.provider.apiKey || "");
        setUseSystemMapping(data.modelConfig.useSystemMapping);

        if (data.modelConfig.customMapping) {
          setCustomModels(data.modelConfig.customMapping);
        } else {
          // 尝试从本地存储恢复
          const saved = localStorage.getItem("claude-code-nexus-custom-mapping");
          if (saved) {
            try {
              setCustomModels(JSON.parse(saved));
            } catch (e) {
              setCustomModels({});
            }
          } else {
            setCustomModels({});
          }
        }
      })
      .catch((err) => {
        console.error("Failed to fetch config:", err);
        let errorMessage = "加载配置失败";
        if (err instanceof Error) {
          errorMessage = err.message;
        }
        setConfigLoadError(errorMessage);
      })
      .finally(() => setIsLoading(false));
  }, [isAuthenticated, isAuthLoading]);

  // 保存配置
  const handleSave = async () => {
    setIsSaving(true);
    setSaveStatus({ type: null, message: null }); // 清除之前的状态

    try {
      const provider = { baseUrl, apiKey };
      const modelConfig = {
        useSystemMapping,
        customMapping: useSystemMapping ? undefined : customModels,
      };

      const response = await fetchWithAuth("/api/config", {
        method: "PUT",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ provider, modelConfig }),
      });

      if (response.ok) {
        // 保存自定义映射到本地存储
        if (!useSystemMapping) {
          localStorage.setItem("claude-code-nexus-custom-mapping", JSON.stringify(customModels));
        }
        setSaveStatus({ type: "success", message: "配置保存成功！" });

        // 3秒后自动清除成功消息
        setTimeout(() => {
          setSaveStatus({ type: null, message: null });
        }, 3000);
      } else {
        // 处理HTTP错误
        let errorMessage = `保存配置失败 (HTTP ${response.status})`;
        try {
          const errorData = await response.json();
          if (errorData.error?.message) {
            errorMessage += `: ${errorData.error.message}`;
          } else if (errorData.message) {
            errorMessage += `: ${errorData.message}`;
          }
        } catch (parseError) {
          errorMessage += `: ${response.statusText}`;
        }
        setSaveStatus({ type: "error", message: errorMessage });
      }
    } catch (error) {
      // 处理网络错误或其他异常
      let errorMessage = "保存配置时发生错误";
      if (error instanceof TypeError && error.message.includes("fetch")) {
        errorMessage = "网络连接失败，请检查网络设置";
      } else if (error instanceof Error) {
        errorMessage = `保存配置失败: ${error.message}`;
      }
      setSaveStatus({ type: "error", message: errorMessage });
    } finally {
      setIsSaving(false);
    }
  };

  // 获取模型列表
  const fetchModels = async () => {
    if (!apiKey || !baseUrl) {
      setModelFetchError("请先配置API Key和Base URL");
      return;
    }

    setIsFetchingModels(true);
    setModelFetchError(null); // 清除之前的错误

    // 修正：直接使用用户提供的baseUrl，在后面加上/models
    const modelsUrl = baseUrl.endsWith("/") ? `${baseUrl}models` : `${baseUrl}/models`;

    try {
      const response = await fetch(modelsUrl, {
        headers: {
          Authorization: `Bearer ${apiKey}`,
          "Content-Type": "application/json",
        },
      });

      if (response.ok) {
        const { data } = await response.json();
        const models = data
          .map((model: any) => ({ id: model.id, name: model.id }))
          .sort((a: any, b: any) => a.name.localeCompare(b.name));
        setModels(models);
        setLastFetchAttempt(new Date());
      } else {
        // 处理HTTP错误
        let errorMessage = `获取模型列表失败 (HTTP ${response.status})`;
        try {
          const errorData = await response.json();
          if (errorData.error?.message) {
            errorMessage += `: ${errorData.error.message}`;
          } else if (errorData.message) {
            errorMessage += `: ${errorData.message}`;
          }
        } catch (parseError) {
          // 如果无法解析错误响应，使用状态文本
          errorMessage += `: ${response.statusText}`;
        }
        errorMessage += `<br/>请求地址: ${modelsUrl}`;
        setModelFetchError(errorMessage);
        setModels([]);
      }
    } catch (error) {
      // 处理网络错误或其他异常
      let errorMessage = "获取模型列表时发生错误";
      if (error instanceof TypeError && error.message.includes("fetch")) {
        errorMessage = "网络连接失败，请检查网络设置或API地址是否正确";
      } else if (error instanceof Error) {
        errorMessage = `获取模型列表失败: ${error.message}`;
      }
      errorMessage += `<br/>请求地址: ${modelsUrl}`;
      setModelFetchError(errorMessage);
      setModels([]);
    } finally {
      setIsFetchingModels(false);
    }
  };

  // 切换映射模式
  const toggleMappingMode = (useSystem: boolean) => {
    if (!useSystem && useSystemMapping) {
      // 切换到自定义时，尝试从本地存储恢复
      const saved = localStorage.getItem("claude-code-nexus-custom-mapping");
      if (saved) {
        try {
          setCustomModels(JSON.parse(saved));
        } catch (e) {
          setCustomModels({});
        }
      }
    }
    setUseSystemMapping(useSystem);
  };

  // 重置到系统默认
  const resetToSystemMapping = async () => {
    try {
      const response = await fetchWithAuth("/api/config/reset", { method: "POST" });
      if (response.ok) {
        setUseSystemMapping(true);
        setCustomModels({});
        setSaveStatus({ type: "success", message: "已重置到系统默认配置！" });

        // 3秒后自动清除成功消息
        setTimeout(() => {
          setSaveStatus({ type: null, message: null });
        }, 3000);
      } else {
        // 处理HTTP错误
        let errorMessage = `重置配置失败 (HTTP ${response.status})`;
        try {
          const errorData = await response.json();
          if (errorData.error?.message) {
            errorMessage += `: ${errorData.error.message}`;
          } else if (errorData.message) {
            errorMessage += `: ${errorData.message}`;
          }
        } catch (parseError) {
          errorMessage += `: ${response.statusText}`;
        }
        setSaveStatus({ type: "error", message: errorMessage });
      }
    } catch (error) {
      // 处理网络错误或其他异常
      let errorMessage = "重置配置时发生错误";
      if (error instanceof TypeError && error.message.includes("fetch")) {
        errorMessage = "网络连接失败，请检查网络设置";
      } else if (error instanceof Error) {
        errorMessage = `重置配置失败: ${error.message}`;
      }
      setSaveStatus({ type: "error", message: errorMessage });
    }
  };

  // 更新自定义模型映射
  const updateCustomModel = (key: string, value: string) => {
    setCustomModels((prev) => ({ ...prev, [key]: value }));
  };

  if (isAuthLoading || isLoading) {
    return <CircularProgress />;
  }

  if (!isAuthenticated) {
    return <Alert severity="info">请先登录以访问控制台</Alert>;
  }

  const baseUrlOrigin = window.location.origin;
  const formatApiKeyForDisplay = (apiKey: string) => {
    if (!apiKey || apiKey.length <= 16) return apiKey;
    const prefix = apiKey.substring(0, 8);
    const suffix = apiKey.substring(apiKey.length - 8);
    const middle = "*".repeat(Math.max(0, apiKey.length - 16));
    return `${prefix}${middle}${suffix}`;
  };

  return (
    <Container maxWidth="lg" sx={{ py: 4 }}>
      <Typography variant="h3" component="h1" gutterBottom>
        控制台
      </Typography>

      {/* 配置加载错误显示 */}
      {configLoadError && (
        <Alert
          severity="error"
          sx={{ mb: 4 }}
          action={
            <Button color="inherit" size="small" onClick={() => window.location.reload()}>
              重新加载
            </Button>
          }
        >
          <Typography variant="body2" sx={{ mb: 1 }}>
            <strong>配置加载失败</strong>
          </Typography>
          <Typography variant="body2" sx={{ mb: 1 }}>
            {configLoadError}
          </Typography>
          <Typography variant="caption" color="text.secondary">
            请检查网络连接或稍后重试
          </Typography>
        </Alert>
      )}

      {/* CLI 配置信息 */}
      <Card sx={{ mb: 4 }}>
        <CardContent>
          <Typography variant="h6">CLI 配置</Typography>
          <Paper sx={{ p: 2, my: 2 }}>
            <Typography variant="body2" color="text.secondary">
              ANTHROPIC_BASE_URL
            </Typography>
            <Box sx={{ display: "flex", alignItems: "center" }}>
              <Typography sx={{ fontFamily: "monospace", flexGrow: 1 }}>{baseUrlOrigin}</Typography>
              <IconButton onClick={() => navigator.clipboard.writeText(baseUrlOrigin)}>
                <CopyIcon />
              </IconButton>
            </Box>
          </Paper>
          <Paper sx={{ p: 2 }}>
            <Typography variant="body2" color="text.secondary">
              ANTHROPIC_API_KEY
            </Typography>
            <Box sx={{ display: "flex", alignItems: "center" }}>
              <Typography sx={{ fontFamily: "monospace", flexGrow: 1 }}>
                {formatApiKeyForDisplay(user?.apiKey || "")}
              </Typography>
              <IconButton onClick={() => navigator.clipboard.writeText(user?.apiKey || "")}>
                <CopyIcon />
              </IconButton>
            </Box>
          </Paper>
        </CardContent>
      </Card>

      {/* API 服务提供商配置 */}
      <Card sx={{ mb: 4 }}>
        <CardContent>
          <Typography variant="h6" sx={{ mb: 2 }}>
            API 服务提供商
          </Typography>
          <Grid container spacing={2}>
            <Grid item xs={12} md={6}>
              <Box sx={{ display: "flex", gap: 1, alignItems: "flex-start" }}>
                <Autocomplete
                  options={PRESET_API_PROVIDERS}
                  getOptionLabel={(option) => (typeof option === "string" ? option : option.baseUrl)}
                  value={PRESET_API_PROVIDERS.find((p) => p.baseUrl === baseUrl) || baseUrl}
                  onInputChange={(event, newInputValue) => {
                    // event.type === 'change' 表示用户正在输入
                    if (event && event.type === "change") {
                      setBaseUrl(newInputValue);
                    }
                  }}
                  onChange={(event, newValue) => {
                    if (typeof newValue === "string") {
                      setBaseUrl(newValue);
                    } else if (newValue) {
                      setBaseUrl(newValue.baseUrl);
                    }
                  }}
                  freeSolo
                  sx={{ flexGrow: 1 }}
                  renderInput={(params) => (
                    <TextField
                      {...params}
                      label="OpenAI 源站 Base URL"
                      placeholder="选择预设供应商或输入自定义地址"
                      fullWidth
                    />
                  )}
                  renderOption={(props, option) => (
                    <Box component="li" {...props}>
                      <Box>
                        <Typography variant="body2" fontWeight="medium">
                          {option.name}
                        </Typography>
                        <Typography variant="caption" color="text.secondary">
                          {option.baseUrl}
                        </Typography>
                      </Box>
                    </Box>
                  )}
                />
                {baseUrl && (
                  <Button
                    variant="outlined"
                    onClick={() => {
                      try {
                        const url = new URL(baseUrl);
                        window.open(`${url.protocol}//${url.host}`, "_blank");
                      } catch (error) {
                        console.error("Invalid URL:", error);
                      }
                    }}
                    sx={{ minWidth: "100px", height: "56px" }}
                    title="前往源站"
                  >
                    前往源站
                  </Button>
                )}
              </Box>
            </Grid>
            <Grid item xs={12} md={6}>
              <TextField
                value={apiKey}
                onChange={(e) => setApiKey(e.target.value)}
                label="OpenAI 源站 API Key"
                type="password"
                fullWidth
                placeholder="请输入您的API密钥"
              />
            </Grid>
          </Grid>
        </CardContent>

        {/* 模型映射配置 */}
        <CardContent>
          <Box sx={{ display: "flex", justifyContent: "space-between", alignItems: "center", mb: 3 }}>
            <Typography variant="h6">模型映射配置</Typography>
            <Button onClick={fetchModels} startIcon={<CloudDownloadIcon />} disabled={isFetchingModels}>
              {isFetchingModels ? "正在获取..." : "获取模型列表"}
            </Button>
          </Box>

          {/* 错误状态显示 */}
          {modelFetchError && (
            <Alert
              severity="error"
              sx={{ mb: 3 }}
              action={
                <Button color="inherit" size="small" onClick={fetchModels} disabled={isFetchingModels}>
                  重试
                </Button>
              }
            >
              <Typography variant="body2" sx={{ mb: 1 }}>
                <strong>获取模型列表失败</strong>
              </Typography>
              <Typography variant="body2" sx={{ mb: 1 }}>
                {modelFetchError}
              </Typography>
              <Typography variant="caption" color="text.secondary">
                请注意，并非所有API供应商都实现了模型列表接口。如果确认信息无误仍无法拉取模型列表可手动在下方填写目标模型名称。
              </Typography>
            </Alert>
          )}

          {/* 成功状态显示 */}
          {models.length > 0 && !modelFetchError && (
            <Alert severity="success" sx={{ mb: 3 }}>
              <Typography variant="body2">
                成功获取到 {models.length} 个模型
                {lastFetchAttempt && (
                  <span style={{ marginLeft: 8, opacity: 0.7 }}>
                    (最后更新: {lastFetchAttempt.toLocaleTimeString()})
                  </span>
                )}
              </Typography>
            </Alert>
          )}

          {/* 无模型状态显示 */}
          {models.length === 0 && !modelFetchError && !isFetchingModels && (
            <Alert severity="info" sx={{ mb: 3 }}>
              <Typography variant="body2">尚未获取模型列表，请点击"获取模型列表"按钮开始配置</Typography>
            </Alert>
          )}

          {/* 模式切换 */}
          <Box
            sx={{
              mb: 3,
              p: 2,
              bgcolor: "background.paper",
              borderRadius: 1,
              border: "1px solid",
              borderColor: "divider",
            }}
          >
            <Box sx={{ display: "flex", alignItems: "center", justifyContent: "space-between" }}>
              <Box sx={{ display: "flex", alignItems: "center" }}>
                {useSystemMapping ? (
                  <AutoModeIcon sx={{ mr: 1, color: "primary.main" }} />
                ) : (
                  <SettingsIcon sx={{ mr: 1, color: "secondary.main" }} />
                )}
                <Typography variant="subtitle1" sx={{ mr: 2 }}>
                  {useSystemMapping ? "系统默认映射" : "自定义映射"}
                </Typography>
                <Chip
                  label={useSystemMapping ? "自动" : "自定义"}
                  size="small"
                  color={useSystemMapping ? "primary" : "secondary"}
                  variant="outlined"
                />
              </Box>
              <Box sx={{ display: "flex", alignItems: "center", gap: 1 }}>
                <Typography variant="body2" color="text.secondary">
                  系统默认
                </Typography>
                <IconButton
                  onClick={() => toggleMappingMode(!useSystemMapping)}
                  color={!useSystemMapping ? "secondary" : "primary"}
                >
                  {useSystemMapping ? <ToggleOffIcon /> : <ToggleOnIcon />}
                </IconButton>
                <Typography variant="body2" color="text.secondary">
                  自定义配置
                </Typography>
              </Box>
            </Box>
          </Box>

          {/* 模型映射列表 */}
          <Typography variant="subtitle2" sx={{ mb: 2, fontWeight: 600 }}>
            Claude 模型映射配置
          </Typography>

          {FIXED_MODEL_RULES.map((rule) => {
            const modelKey = rule.keyword;
            const systemValue = DEFAULT_MAPPING_CONFIG[modelKey as keyof typeof DEFAULT_MAPPING_CONFIG];
            const currentValue = useSystemMapping ? systemValue : customModels[modelKey] || "";

            return (
              <Grid container spacing={2} sx={{ mb: 2, alignItems: "center" }} key={modelKey}>
                <Grid item xs={12} md={3}>
                  <TextField
                    value={rule.keyword}
                    label="模型类型"
                    fullWidth
                    disabled
                    sx={{
                      "& .MuiInputBase-input.Mui-disabled": {
                        WebkitTextFillColor: theme.palette.text.primary,
                        opacity: 0.7,
                      },
                    }}
                  />
                </Grid>
                <Grid item xs={12} md={6}>
                  <Autocomplete
                    options={models.map((m) => m.name)}
                    value={currentValue}
                    onInputChange={(event, newInputValue) => {
                      if (!useSystemMapping) {
                        updateCustomModel(modelKey, newInputValue);
                      }
                    }}
                    disabled={useSystemMapping}
                    freeSolo
                    renderInput={(params) => (
                      <TextField {...params} label="目标模型" placeholder="选择模型或输入自定义模型名" fullWidth />
                    )}
                    renderOption={(props, option) => (
                      <Box component="li" {...props}>
                        <Typography variant="body2">{option}</Typography>
                      </Box>
                    )}
                  />
                </Grid>
                <Grid item xs={12} md={3}>
                  <Typography variant="body2" color="text.secondary">
                    {rule.description}
                  </Typography>
                </Grid>
              </Grid>
            );
          })}

          <Box sx={{ mt: 4, display: "flex", justifyContent: "flex-end", gap: 2 }}>
            {/* <Button onClick={resetToSystemMapping} startIcon={<RefreshIcon />} variant="outlined">
              重置到系统默认
            </Button> */}
            <Button onClick={handleSave} variant="contained" size="large" startIcon={<SaveIcon />} disabled={isSaving}>
              {isSaving ? "保存中..." : "保存配置"}
            </Button>
          </Box>

          {/* 保存状态显示 */}
          {saveStatus.type && (
            <Box sx={{ mt: 2 }}>
              <Alert
                severity={saveStatus.type}
                action={
                  saveStatus.type === "error" && (
                    <Button color="inherit" size="small" onClick={() => setSaveStatus({ type: null, message: null })}>
                      关闭
                    </Button>
                  )
                }
              >
                <Typography variant="body2">{saveStatus.message}</Typography>
              </Alert>
            </Box>
          )}
        </CardContent>
      </Card>

      {/* Claude Code 使用教程 */}
      <Card sx={{ mt: 4 }}>
        <CardContent>
          <Typography variant="h6" sx={{ mb: 3, display: "flex", alignItems: "center" }}>
            <Box
              component="span"
              sx={{
                display: "inline-block",
                width: 24,
                height: 24,
                borderRadius: "50%",
                bgcolor: "primary.main",
                color: "white",
                textAlign: "center",
                lineHeight: "24px",
                fontSize: "14px",
                fontWeight: "bold",
                mr: 2,
              }}
            >
              💻
            </Box>
            Claude Code 使用教程
          </Typography>

          <Box sx={{ mb: 3 }}>
            <Typography variant="subtitle1" sx={{ mb: 2, fontWeight: 600, color: "primary.main" }}>
              1️⃣ 安装 Node.js（已安装可跳过）
            </Typography>
            <Typography variant="body2" color="text.secondary" sx={{ mb: 2 }}>
              确保 Node.js 版本 ≥ 18.0
            </Typography>
            <Box
              component="pre"
              sx={{
                bgcolor: theme.palette.mode === "dark" ? "grey.900" : "grey.100",
                p: 2,
                borderRadius: 1,
                overflow: "auto",
                fontSize: "0.875rem",
                border: `1px solid ${theme.palette.divider}`,
              }}
            >
              <code>{`# Ubuntu / Debian 用户
curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo bash -
sudo apt-get install -y nodejs
node --version

# macOS 用户
brew install node
node --version`}</code>
            </Box>
          </Box>

          <Box sx={{ mb: 3 }}>
            <Typography variant="subtitle1" sx={{ mb: 2, fontWeight: 600, color: "primary.main" }}>
              2️⃣ 安装 Claude Code
            </Typography>
            <Box
              component="pre"
              sx={{
                bgcolor: theme.palette.mode === "dark" ? "grey.900" : "grey.100",
                p: 2,
                borderRadius: 1,
                overflow: "auto",
                fontSize: "0.875rem",
                border: `1px solid ${theme.palette.divider}`,
              }}
            >
              <code>{`npm install -g @anthropic-ai/claude-code
claude --version`}</code>
            </Box>
          </Box>

          <Box sx={{ mb: 3 }}>
            <Typography variant="subtitle1" sx={{ mb: 2, fontWeight: 600, color: "primary.main" }}>
              3️⃣ 开始使用
            </Typography>

            <Alert severity="info" sx={{ mb: 2 }}>
              <Typography variant="body2">
                <strong>变量配置：</strong>请将以下环境变量配置到您的终端环境中，Claude Code 将自动使用这些配置
              </Typography>
            </Alert>

            <Grid container spacing={2} sx={{ mb: 2 }}>
              <Grid item xs={12} sm={6}>
                <Box
                  sx={{
                    p: 2,
                    bgcolor: "background.paper",
                    borderRadius: 1,
                    border: `1px solid ${theme.palette.divider}`,
                  }}
                >
                  <Typography variant="subtitle2" sx={{ mb: 1, color: "text.secondary" }}>
                    您的API Key (ANTHROPIC_AUTH_TOKEN)
                  </Typography>
                  <Box sx={{ display: "flex", alignItems: "center", gap: 1 }}>
                    <Typography
                      variant="body2"
                      component="code"
                      sx={{
                        flex: 1,
                        p: 1,
                        bgcolor: theme.palette.mode === "dark" ? "grey.800" : "grey.50",
                        borderRadius: 0.5,
                        fontSize: "0.75rem",
                        wordBreak: "break-all",
                      }}
                    >
                      {user?.apiKey ? `${user.apiKey.substring(0, 20)}...` : "ak-..."}
                    </Typography>
                    {user?.apiKey && (
                      <IconButton
                        size="small"
                        onClick={() => navigator.clipboard.writeText(user.apiKey)}
                        title="复制API Key"
                      >
                        <CopyIcon fontSize="small" />
                      </IconButton>
                    )}
                  </Box>
                  <Typography variant="caption" color="text.secondary" sx={{ mt: 1, display: "block" }}>
                    这是您在我们系统的专属API Key
                  </Typography>
                </Box>
              </Grid>
              <Grid item xs={12} sm={6}>
                <Box
                  sx={{
                    p: 2,
                    bgcolor: "background.paper",
                    borderRadius: 1,
                    border: `1px solid ${theme.palette.divider}`,
                  }}
                >
                  <Typography variant="subtitle2" sx={{ mb: 1, color: "text.secondary" }}>
                    代理地址 (ANTHROPIC_BASE_URL)
                  </Typography>
                  <Box sx={{ display: "flex", alignItems: "center", gap: 1 }}>
                    <Typography
                      variant="body2"
                      component="code"
                      sx={{
                        flex: 1,
                        p: 1,
                        bgcolor: theme.palette.mode === "dark" ? "grey.800" : "grey.50",
                        borderRadius: 0.5,
                        fontSize: "0.75rem",
                      }}
                    >
                      https://claudeapi-1.satoshitech.xyz
                    </Typography>
                    <IconButton
                      size="small"
                      onClick={() => navigator.clipboard.writeText("https://claudeapi-1.satoshitech.xyz")}
                      title="复制代理地址"
                    >
                      <CopyIcon fontSize="small" />
                    </IconButton>
                  </Box>
                  <Typography variant="caption" color="text.secondary" sx={{ mt: 1, display: "block" }}>
                    我们的Claude API代理服务地址
                  </Typography>
                </Box>
              </Grid>
            </Grid>

            <Typography variant="body2" color="text.secondary" sx={{ mb: 2 }}>
              在您的项目目录下运行：
            </Typography>
            <Box
              component="pre"
              sx={{
                bgcolor: theme.palette.mode === "dark" ? "grey.900" : "grey.100",
                p: 2,
                borderRadius: 1,
                overflow: "auto",
                fontSize: "0.875rem",
                border: `1px solid ${theme.palette.divider}`,
              }}
            >
              <code>{`# 如果需要在终端中自动使用配置，可以以下内容添加到 \`.bashrc\` 或 \`.zshrc\` 中
export ANTHROPIC_AUTH_TOKEN="${user?.apiKey || "ak-your-api-key"}"
export ANTHROPIC_BASE_URL="https://claudeapi-1.satoshitech.xyz"

# 运行 Claude Code
claude`}</code>
            </Box>
          </Box>

          <Alert severity="success">
            <Typography variant="body2">
              <strong>提示：</strong>配置完成后，Claude Code
              将使用您设置的模型映射规则，自动将Claude模型请求转换为对应的目标模型。
            </Typography>
          </Alert>
        </CardContent>
      </Card>
    </Container>
  );
}
