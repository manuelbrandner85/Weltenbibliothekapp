/**
 * ═══════════════════════════════════════════════════════════════
 * AUTH UTILITIES - Password Hashing & JWT
 * ═══════════════════════════════════════════════════════════════
 * ECHTE Authentifizierung mit PBKDF2 und JWT-Tokens
 * ═══════════════════════════════════════════════════════════════
 */

// ═══════════════════════════════════════════════════════════════
// PASSWORD HASHING (PBKDF2)
// ═══════════════════════════════════════════════════════════════

export async function hashPassword(password, providedSalt) {
  const encoder = new TextEncoder();
  const salt = providedSalt || crypto.getRandomValues(new Uint8Array(16));
  
  const keyMaterial = await crypto.subtle.importKey(
    "raw",
    encoder.encode(password),
    { name: "PBKDF2" },
    false,
    ["deriveBits", "deriveKey"]
  );
  
  const key = await crypto.subtle.deriveKey(
    {
      name: "PBKDF2",
      salt: salt,
      iterations: 100000,
      hash: "SHA-256",
    },
    keyMaterial,
    { name: "AES-GCM", length: 256 },
    true,
    ["encrypt", "decrypt"]
  );
  
  const exportedKey = await crypto.subtle.exportKey("raw", key);
  const hashBuffer = new Uint8Array(exportedKey);
  const hashHex = Array.from(hashBuffer).map(b => b.toString(16).padStart(2, "0")).join("");
  const saltHex = Array.from(salt).map(b => b.toString(16).padStart(2, "0")).join("");
  
  return `${saltHex}:${hashHex}`;
}

export async function verifyPassword(storedHash, passwordAttempt) {
  const [saltHex, originalHash] = storedHash.split(":");
  const matchResult = saltHex.match(/.{1,2}/g);
  
  if (!matchResult) {
    throw new Error("Invalid salt format");
  }
  
  const salt = new Uint8Array(matchResult.map(byte => parseInt(byte, 16)));
  const attemptHashWithSalt = await hashPassword(passwordAttempt, salt);
  const [, attemptHash] = attemptHashWithSalt.split(":");
  
  return attemptHash === originalHash;
}

// ═══════════════════════════════════════════════════════════════
// JWT TOKEN HANDLING
// ═══════════════════════════════════════════════════════════════

const JWT_SECRET = "weltenbibliothek_secret_key_2025"; // In production: use env variable

export async function generateJWT(payload) {
  const header = {
    alg: "HS256",
    typ: "JWT"
  };
  
  const now = Math.floor(Date.now() / 1000);
  const jwtPayload = {
    ...payload,
    iat: now,
    exp: now + (7 * 24 * 60 * 60) // 7 days
  };
  
  const encodedHeader = btoa(JSON.stringify(header));
  const encodedPayload = btoa(JSON.stringify(jwtPayload));
  
  const message = `${encodedHeader}.${encodedPayload}`;
  const signature = await signHMAC(message, JWT_SECRET);
  
  return `${message}.${signature}`;
}

export async function verifyJWT(token) {
  try {
    const [encodedHeader, encodedPayload, providedSignature] = token.split('.');
    
    if (!encodedHeader || !encodedPayload || !providedSignature) {
      return null;
    }
    
    const message = `${encodedHeader}.${encodedPayload}`;
    const expectedSignature = await signHMAC(message, JWT_SECRET);
    
    if (expectedSignature !== providedSignature) {
      return null;
    }
    
    const payload = JSON.parse(atob(encodedPayload));
    
    // Check expiration
    const now = Math.floor(Date.now() / 1000);
    if (payload.exp && payload.exp < now) {
      return null;
    }
    
    return payload;
  } catch (error) {
    console.error('JWT verification error:', error);
    return null;
  }
}

async function signHMAC(message, secret) {
  const encoder = new TextEncoder();
  const key = await crypto.subtle.importKey(
    "raw",
    encoder.encode(secret),
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["sign"]
  );
  
  const signature = await crypto.subtle.sign(
    "HMAC",
    key,
    encoder.encode(message)
  );
  
  const signatureArray = Array.from(new Uint8Array(signature));
  return btoa(String.fromCharCode(...signatureArray))
    .replace(/\+/g, '-')
    .replace(/\//g, '_')
    .replace(/=/g, '');
}

export function extractUserFromToken(authHeader) {
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return null;
  }
  
  const token = authHeader.substring(7);
  // Simple extraction from demo token format for backward compatibility
  if (token.startsWith('demo_token_')) {
    const parts = token.split('_');
    return { username: parts[2], userId: 'user_' + parts[2] };
  }
  
  // For JWT tokens, we'll decode properly
  try {
    const [, payload] = token.split('.');
    const decoded = JSON.parse(atob(payload));
    return {
      userId: decoded.userId,
      username: decoded.username,
      role: decoded.role
    };
  } catch (e) {
    return null;
  }
}
