# CURRENT IMPLEMENTATION PLAN - Wraith Daemon Improvements

## **Overview**
This plan addresses edge cases, logging memory overflow, and error handling improvements for the Wraith real-time dictation daemon.

## **1. Error Handling Fixes**

### **1.1 Fix Variable Mismatch in browser.js**
- **File**: `src/browser.js`
- **Issue**: `err` variable referenced but catch uses `e` (lines 73, 83)
- **Fix**: Standardize to use `e` parameter consistently
- **Impact**: Proper error logging in browser context

### **1.2 Add WSA Error Handling**
- **Location**: `src/browser.js` error handlers
- **Implementation**:
  - Enhance `rec.onerror` to categorize errors
  - Add specific messages for network/permission issues
  - Propagate errors to server via exposed function
- **Error Types**:
  - Network errors: "Network unavailable - Web Speech API requires internet"
  - Permission errors: "Microphone access denied - check browser settings"
  - Other errors: Log with error code/details

## **2. State Synchronization Improvement**

### **2.1 Server-Side Validation**
- **File**: `src/index.ts`
- **Changes**:
  - Add `isBrowserReady()` check before WSA operations
  - Validate `window.recognition` state indirectly via error handling
  - Maintain `isListening` flag with additional validation steps
- **No Performance Impact**: Avoid `page.evaluate` for state checks

### **2.2 Browser-Side Safety Checks**
- **File**: `src/browser.js`
- **Changes**:
  - Add null checks for `window.recognition`
  - Validate recognition state before start/stop
  - Return status codes for server to interpret

## **3. Log Rotation System (10MB Limit)**

### **3.1 LogManager Class**
- **File**: `src/log-manager.ts` (new)
- **Features**:
  - Byte-based rotation (10MB per instance)
  - Immediate garbage collection of oldest logs
  - Simple API: `log(message: string)`
  - Separate instances for server/browser logs
- **Implementation**:
```typescript
class LogManager {
  private buffer: string[] = [];
  private maxSizeBytes: number;
  private currentSize = 0;
  
  constructor(maxMB = 10) {
    this.maxSizeBytes = maxMB * 1024 * 1024;
  }
  
  log(message: string): void {
    const msgSize = Buffer.byteLength(message, 'utf8');
    
    // Remove oldest if over limit
    while (this.currentSize + msgSize > this.maxSizeBytes && this.buffer.length > 0) {
      const removed = this.buffer.shift()!;
      this.currentSize -= Buffer.byteLength(removed, 'utf8');
    }
    
    this.buffer.push(message);
    this.currentSize += msgSize;
    console.log(message); // Still output to stdout
  }
}
```

### **3.2 Integration**
- **Server Logs**: Use LogManager instance in `Daemon.log()` method
- **Browser Logs**: Continue direct `console.log` (bypass rotation)
- **Format**: Simplified messages without `[DAEMON]` prefix

## **4. Enhanced Error Logging**

### **4.1 Server-Side Error Categories**
- **Network Issues**: Log as warning, continue operation
- **Permission Issues**: Log as warning, user action required
- **WSA Failures**: Log as error, maintain daemon state
- **Browser Errors**: Capture via page console events

### **4.2 Error Propagation**
- Browser errors → exposed function → server LogManager
- No retry logic, just informative logging
- Future-ready for notification system integration

## **5. Race Condition Considerations**

### **5.1 Current Protection**
- Server-side `isListening` flag prevents duplicate starts/stops
- HTTP request sequencing handles user-triggered races
- No additional complexity needed for single-user scenario

### **5.2 Edge Cases Handled**
- Rapid F9/F10 presses: Server flag prevents duplicate processing
- Network delays: Sequential HTTP processing maintains order
- Browser state lag: Error logging captures timing issues

## **6. Implementation Sequence**

### **Phase 1: Core Fixes**
1. Fix `err`/`e` variable mismatch in `browser.js`
2. Create `LogManager` class with 10MB rotation
3. Integrate LogManager into Daemon class

### **Phase 2: Error Handling**
4. Enhance WSA error categorization in browser
5. Add server-side error logging for network/permission issues
6. Propagate browser errors to server logs

### **Phase 3: State Management**
7. Add server-side validation methods
8. Implement browser-side safety checks
9. Update HTTP endpoints with improved validation

### **Phase 4: Testing & Validation**
10. Verify log rotation works correctly
11. Test error scenarios produce appropriate logs
12. Confirm state synchronization improvements

## **7. Files to Modify/Create**

### **Modified Files:**
- `src/browser.js` - Error handling, safety checks
- `src/index.ts` - Log integration, validation methods

### **New Files:**
- `src/log-manager.ts` - Log rotation implementation

### **Configuration:**
- 10MB limit per LogManager instance
- Immediate garbage collection on overflow
- Simplified log format (no prefixes)

## **8. Success Criteria**

- [ ] Error variable mismatch fixed
- [ ] Log rotation prevents memory overflow (>10MB)
- [ ] Network/permission errors logged appropriately
- [ ] State validation prevents invalid WSA operations
- [ ] Browser errors propagate to server logs
- [ ] No performance degradation in normal operation

## **9. Future Considerations**

- Notification system integration (libnotify)
- `dotool` text injection implementation
- Phantom Backspace logic for real-time correction
- Health check endpoints
- Log retrieval API for debugging

---

**Next Step**: Switch to Code mode to implement Phase 1 fixes.