# API Contracts

## GitHub REST API

### Search Issues (Draft Status)

**Endpoint**: `GET /search/issues`

**Response Item Update**:
```json
{
  "number": 123,
  "title": "WIP: Feature",
  "draft": true, // New field
  ...
}
```

### PR Details (Mergeability)

**Endpoint**: `GET /repos/{owner}/{repo}/pulls/{number}`

**Response Update**:
```json
{
  "mergeable": true, // or false, or null
  "mergeable_state": "clean", // or "dirty", "unstable", "unknown"
  "head": {
    "sha": "6dcb09b5b57875f334f61aebed695e2e4193db5e"
  },
  ...
}
```

### Check Runs (CI Status)

**Endpoint**: `GET /repos/{owner}/{repo}/commits/{ref}/check-runs`

**Response**:
```json
{
  "total_count": 5,
  "check_runs": [
    {
      "status": "completed",
      "conclusion": "success",
      "name": "Build"
    },
    {
      "status": "in_progress",
      "conclusion": null,
      "name": "Tests"
    }
  ]
}
```
