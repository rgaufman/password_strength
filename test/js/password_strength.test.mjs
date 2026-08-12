import assert from "node:assert/strict";
import { createRequire } from "node:module";
import { describe, it } from "node:test";

const require = createRequire(import.meta.url);
const PasswordStrength = require("../../app/assets/javascripts/password_strength.js");

describe("minimum length", () => {
  it("applies no minimum by default", () => {
    const strength = PasswordStrength.test("johndoe", "^P4ss$");

    assert.notEqual(strength.status, "invalid");
    assert.equal(strength.invalidReason, null);
  });

  it("rejects a password under the minimum", () => {
    const strength = PasswordStrength.test("johndoe", "^P4ssw0rd$", { minLength: 12 });

    assert.equal(strength.status, "invalid");
    assert.equal(strength.invalidReason, "too_short");
    assert.equal(strength.isValid("weak"), false);
  });

  it("accepts a password on the minimum", () => {
    const strength = PasswordStrength.test("johndoe", "^P4ssw0rd12$", { minLength: 12 });

    assert.equal(strength.status, "strong");
    assert.equal(strength.invalidReason, null);
  });

  it("counts characters rather than UTF-16 units", () => {
    const strength = PasswordStrength.test("johndoe", "çãéíóúàèìòù^1$", { minLength: 12 });

    assert.equal(strength.isTooShort(), false);
  });
});

describe("blocklist", () => {
  it("rejects a bundled common password", () => {
    const strength = PasswordStrength.test("johndoe", "password");

    assert.equal(strength.invalidReason, "common_word");
  });

  it("rejects a common password written in leet", () => {
    const strength = PasswordStrength.test("johndoe", "P@ssw0rd");

    assert.equal(strength.invalidReason, "common_word");
  });

  it("rejects a common password followed by digits", () => {
    const strength = PasswordStrength.test("johndoe", "monkey2024");

    assert.equal(strength.invalidReason, "common_word");
  });

  it("accepts a passphrase that merely contains a common word", () => {
    const strength = PasswordStrength.test("johndoe", "blue-River-42-lamp");

    assert.equal(strength.isValid("good"), true);
  });

  it("uses a supplied list in place of the bundled one", () => {
    PasswordStrength.blocklist = ["tetherx"];

    try {
      assert.equal(PasswordStrength.test("johndoe", "T3therX99").invalidReason, "common_word");
      assert.notEqual(PasswordStrength.test("johndoe", "password").status, "invalid");
    } finally {
      PasswordStrength.blocklist = null;
    }
  });
});

describe("rejection reasons", () => {
  it("reports a repeated character", () => {
    const strength = PasswordStrength.test("johndoe", "a".repeat(50));

    assert.equal(strength.invalidReason, "repeated_character");
  });

  it("reports excluded characters", () => {
    const strength = PasswordStrength.test("johndoe", "^Str0ng P4ssw0rd$", { exclude: /\s/ });

    assert.equal(strength.invalidReason, "excluded_characters");
  });
});

describe("sequences", () => {
  it("counts a run of three", () => {
    const strength = PasswordStrength.test("johndoe", "mypass");

    assert.equal(strength.sequences("abc"), 1);
    assert.equal(strength.sequences("aaa"), 1);
  });

  it("does not read a character outside the basic plane as a run", () => {
    const strength = PasswordStrength.test("johndoe", "mypass");

    assert.equal(strength.sequences("😀"), 0);
  });
});

describe("parity with the Ruby scoring", () => {
  const cases = [
    ["sunny", "invalid"],
    ["password1", "invalid"],
    ["Sh0rt!Pass", "invalid"],
    ["P@ssw0rd2026", "invalid"],
    ["aaaaaaaaaaaa", "invalid"],
    ["abcdefghijkl", "weak"],
    ["Coffee7Rain!", "strong"],
    ["blue-River-42-lamp", "strong"]
  ];

  for (const [password, status] of cases) {
    it(`judges ${password} as ${status}`, () => {
      const strength = PasswordStrength.test("james.bond@example.com", password, { minLength: 12 });

      assert.equal(strength.status, status);
    });
  }
});
