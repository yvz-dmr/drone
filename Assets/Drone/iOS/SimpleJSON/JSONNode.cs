﻿
using System;
using System.Collections.Generic;
using System.Globalization;
using System.IO;

namespace SimpleJSON
{
	public abstract class JSONNode
	{
		public virtual void Add(string aKey, JSONNode aItem)
		{
		}

		public virtual JSONNode this[int aIndex]
		{
			get
			{
				return null;
			}
			set
			{
			}
		}

		public virtual JSONNode this[string aKey]
		{
			get
			{
				return null;
			}
			set
			{
			}
		}

		public virtual string Value
		{
			get
			{
				return string.Empty;
			}
			set
			{
			}
		}

		public virtual int Count
		{
			get
			{
				return 0;
			}
		}

		public virtual void Add(JSONNode aItem)
		{
			this.Add(string.Empty, aItem);
		}

		public virtual JSONNode Remove(string aKey)
		{
			return null;
		}

		public virtual JSONNode Remove(int aIndex)
		{
			return null;
		}

		public virtual JSONNode Remove(JSONNode aNode)
		{
			return aNode;
		}

		public virtual IEnumerable<JSONNode> Children
		{
			get
			{
				yield break;
			}
		}

		public IEnumerable<JSONNode> DeepChildren
		{
			get
			{
				foreach (JSONNode C in this.Children)
				{
					foreach (JSONNode D in C.DeepChildren)
					{
						yield return D;
					}
				}
				yield break;
			}
		}

		public override string ToString()
		{
			return "JSONNode";
		}

		public virtual string ToString(string aPrefix)
		{
			return "JSONNode";
		}

		public abstract string ToJSON(int prefix);

		public virtual JSONBinaryTag Tag { get; set; }

		public virtual int AsInt
		{
			get
			{
				int result = 0;
				if (int.TryParse(this.Value, out result))
				{
					return result;
				}
				return 0;
			}
			set
			{
				this.Value = value.ToString();
				this.Tag = JSONBinaryTag.IntValue;
			}
		}

		public virtual float AsFloat
		{
			get
			{
				float result = 0f;
				if (float.TryParse(this.Value, out result))
				{
					return result;
				}
				return 0f;
			}
			set
			{
				this.Value = value.ToString();
				this.Tag = JSONBinaryTag.FloatValue;
			}
		}

		public virtual double AsDouble
		{
			get
			{
				double result = 0.0;
				if (double.TryParse(this.Value, out result))
				{
					return result;
				}
				return 0.0;
			}
			set
			{
				this.Value = value.ToString();
				this.Tag = JSONBinaryTag.DoubleValue;
			}
		}

		public virtual bool AsBool
		{
			get
			{
				bool result = false;
				if (bool.TryParse(this.Value, out result))
				{
					return result;
				}
				return !string.IsNullOrEmpty(this.Value);
			}
			set
			{
				this.Value = ((!value) ? "false" : "true");
				this.Tag = JSONBinaryTag.BoolValue;
			}
		}

		public virtual JSONArray AsArray
		{
			get
			{
				return this as JSONArray;
			}
		}

		public virtual JSONClass AsObject
		{
			get
			{
				return this as JSONClass;
			}
		}

		public static implicit operator JSONNode(string s)
		{
			return new JSONData(s);
		}

		public static implicit operator string(JSONNode d)
		{
			return (!(d == null)) ? d.Value : null;
		}

		public static bool operator ==(JSONNode a, object b)
		{
			return (b == null && a is JSONLazyCreator) || object.ReferenceEquals(a, b);
		}

		public static bool operator !=(JSONNode a, object b)
		{
			return !(a == b);
		}

		public override bool Equals(object obj)
		{
			return object.ReferenceEquals(this, obj);
		}

		public override int GetHashCode()
		{
			return base.GetHashCode();
		}

		internal static string Escape(string aText)
		{
			string text = string.Empty;
			foreach (char c in aText)
			{
				switch (c)
				{
				case '\b':
					text += "\\b";
					break;
				case '\t':
					text += "\\t";
					break;
				case '\n':
					text += "\\n";
					break;
				default:
					if (c != '"')
					{
						if (c != '\\')
						{
							text += c;
						}
						else
						{
							text += "\\\\";
						}
					}
					else
					{
						text += "\\\"";
					}
					break;
				case '\f':
					text += "\\f";
					break;
				case '\r':
					text += "\\r";
					break;
				}
			}
			return text;
		}

		private static JSONData Numberize(string token)
		{
			bool aData = false;
			int aData2 = 0;
			double aData3 = 0.0;
			if (int.TryParse(token, out aData2))
			{
				return new JSONData(aData2);
			}
			if (double.TryParse(token, out aData3))
			{
				return new JSONData(aData3);
			}
			if (bool.TryParse(token, out aData))
			{
				return new JSONData(aData);
			}
			throw new NotImplementedException(token);
		}

		private static void AddElement(JSONNode ctx, string token, string tokenName, bool tokenIsString)
		{
			if (tokenIsString)
			{
				if (ctx is JSONArray)
				{
					ctx.Add(token);
				}
				else
				{
					ctx.Add(tokenName, token);
				}
			}
			else
			{
				JSONData aItem = JSONNode.Numberize(token);
				if (ctx is JSONArray)
				{
					ctx.Add(aItem);
				}
				else
				{
					ctx.Add(tokenName, aItem);
				}
			}
		}

		public static JSONNode Parse(string aJSON)
		{
			Stack<JSONNode> stack = new Stack<JSONNode>();
			JSONNode jsonnode = null;
			int i = 0;
			string text = string.Empty;
			string text2 = string.Empty;
			bool flag = false;
			bool flag2 = false;
			while (i < aJSON.Length)
			{
				char c = aJSON[i];
				switch (c)
				{
				case '\t':
					goto IL_2F3;
				case '\n':
				case '\r':
					break;
				default:
					switch (c)
					{
					case '[':
						if (flag)
						{
							text += aJSON[i];
							goto IL_41C;
						}
						stack.Push(new JSONArray());
						if (jsonnode != null)
						{
							text2 = text2.Trim();
							if (jsonnode is JSONArray)
							{
								jsonnode.Add(stack.Peek());
							}
							else if (text2 != string.Empty)
							{
								jsonnode.Add(text2, stack.Peek());
							}
						}
						text2 = string.Empty;
						text = string.Empty;
						jsonnode = stack.Peek();
						goto IL_41C;
					case '\\':
						i++;
						if (flag)
						{
							char c2 = aJSON[i];
							switch (c2)
							{
							case 'r':
								text += '\r';
								break;
							default:
								if (c2 != 'b')
								{
									if (c2 != 'f')
									{
										if (c2 != 'n')
										{
											text += c2;
										}
										else
										{
											text += '\n';
										}
									}
									else
									{
										text += '\f';
									}
								}
								else
								{
									text += '\b';
								}
								break;
							case 't':
								text += '\t';
								break;
							case 'u':
							{
								string s = aJSON.Substring(i + 1, 4);
								text += (char)int.Parse(s, NumberStyles.AllowHexSpecifier);
								i += 4;
								break;
							}
							}
						}
						goto IL_41C;
					case ']':
						break;
					default:
						switch (c)
						{
						case ' ':
							goto IL_2F3;
						default:
							switch (c)
							{
							case '{':
								if (flag)
								{
									text += aJSON[i];
									goto IL_41C;
								}
								stack.Push(new JSONClass());
								if (jsonnode != null)
								{
									text2 = text2.Trim();
									if (jsonnode is JSONArray)
									{
										jsonnode.Add(stack.Peek());
									}
									else if (text2 != string.Empty)
									{
										jsonnode.Add(text2, stack.Peek());
									}
								}
								text2 = string.Empty;
								text = string.Empty;
								jsonnode = stack.Peek();
								goto IL_41C;
							default:
								if (c != ',')
								{
									if (c != ':')
									{
										text += aJSON[i];
										goto IL_41C;
									}
									if (flag)
									{
										text += aJSON[i];
										goto IL_41C;
									}
									text2 = text;
									text = string.Empty;
									flag2 = false;
									goto IL_41C;
								}
								else
								{
									if (flag)
									{
										text += aJSON[i];
										goto IL_41C;
									}
									if (text != string.Empty)
									{
										JSONNode.AddElement(jsonnode, text, text2, flag2);
									}
									text2 = string.Empty;
									text = string.Empty;
									flag2 = false;
									goto IL_41C;
								}
								break;
							case '}':
								break;
							}
							break;
						case '"':
							flag ^= true;
							flag2 = (flag || flag2);
							goto IL_41C;
						}
						break;
					}
					if (flag)
					{
						text += aJSON[i];
					}
					else
					{
						if (stack.Count == 0)
						{
							throw new Exception("JSON Parse: Too many closing brackets");
						}
						stack.Pop();
						if (text != string.Empty)
						{
							text2 = text2.Trim();
							JSONNode.AddElement(jsonnode, text, text2, flag2);
							flag2 = false;
						}
						text2 = string.Empty;
						text = string.Empty;
						if (stack.Count > 0)
						{
							jsonnode = stack.Peek();
						}
					}
					break;
				}
				IL_41C:
				i++;
				continue;
				IL_2F3:
				if (flag)
				{
					text += aJSON[i];
				}
				goto IL_41C;
			}
			if (flag)
			{
				throw new Exception("JSON Parse: Quotation marks seems to be messed up.");
			}
			return jsonnode;
		}

		public virtual void Serialize(BinaryWriter aWriter)
		{
		}

		public void SaveToStream(Stream aData)
		{
			BinaryWriter aWriter = new BinaryWriter(aData);
			this.Serialize(aWriter);
		}

		public void SaveToCompressedStream(Stream aData)
		{
			throw new Exception("Can't use compressed functions. You need include the SharpZipLib and uncomment the define at the top of SimpleJSON");
		}

		public void SaveToCompressedFile(string aFileName)
		{
			throw new Exception("Can't use compressed functions. You need include the SharpZipLib and uncomment the define at the top of SimpleJSON");
		}

		public string SaveToCompressedBase64()
		{
			throw new Exception("Can't use compressed functions. You need include the SharpZipLib and uncomment the define at the top of SimpleJSON");
		}

		public void SaveToFile(string aFileName)
		{
			Directory.CreateDirectory(new FileInfo(aFileName).Directory.FullName);
			using (FileStream fileStream = File.OpenWrite(aFileName))
			{
				this.SaveToStream(fileStream);
			}
		}

		public string SaveToBase64()
		{
			string result;
			using (MemoryStream memoryStream = new MemoryStream())
			{
				this.SaveToStream(memoryStream);
				memoryStream.Position = 0L;
				result = Convert.ToBase64String(memoryStream.ToArray());
			}
			return result;
		}

		public static JSONNode Deserialize(BinaryReader aReader)
		{
			JSONBinaryTag jsonbinaryTag = (JSONBinaryTag)aReader.ReadByte();
			switch (jsonbinaryTag)
			{
			case JSONBinaryTag.Array:
			{
				int num = aReader.ReadInt32();
				JSONArray jsonarray = new JSONArray();
				for (int i = 0; i < num; i++)
				{
					jsonarray.Add(JSONNode.Deserialize(aReader));
				}
				return jsonarray;
			}
			case JSONBinaryTag.Class:
			{
				int num2 = aReader.ReadInt32();
				JSONClass jsonclass = new JSONClass();
				for (int j = 0; j < num2; j++)
				{
					string aKey = aReader.ReadString();
					JSONNode aItem = JSONNode.Deserialize(aReader);
					jsonclass.Add(aKey, aItem);
				}
				return jsonclass;
			}
			case JSONBinaryTag.Value:
				return new JSONData(aReader.ReadString());
			case JSONBinaryTag.IntValue:
				return new JSONData(aReader.ReadInt32());
			case JSONBinaryTag.DoubleValue:
				return new JSONData(aReader.ReadDouble());
			case JSONBinaryTag.BoolValue:
				return new JSONData(aReader.ReadBoolean());
			case JSONBinaryTag.FloatValue:
				return new JSONData(aReader.ReadSingle());
			default:
				throw new Exception("Error deserializing JSON. Unknown tag: " + jsonbinaryTag);
			}
		}

		public static JSONNode LoadFromCompressedFile(string aFileName)
		{
			throw new Exception("Can't use compressed functions. You need include the SharpZipLib and uncomment the define at the top of SimpleJSON");
		}

		public static JSONNode LoadFromCompressedStream(Stream aData)
		{
			throw new Exception("Can't use compressed functions. You need include the SharpZipLib and uncomment the define at the top of SimpleJSON");
		}

		public static JSONNode LoadFromCompressedBase64(string aBase64)
		{
			throw new Exception("Can't use compressed functions. You need include the SharpZipLib and uncomment the define at the top of SimpleJSON");
		}

		public static JSONNode LoadFromStream(Stream aData)
		{
			JSONNode result;
			using (BinaryReader binaryReader = new BinaryReader(aData))
			{
				result = JSONNode.Deserialize(binaryReader);
			}
			return result;
		}

		public static JSONNode LoadFromFile(string aFileName)
		{
			JSONNode result;
			using (FileStream fileStream = File.OpenRead(aFileName))
			{
				result = JSONNode.LoadFromStream(fileStream);
			}
			return result;
		}

		public static JSONNode LoadFromBase64(string aBase64)
		{
			byte[] buffer = Convert.FromBase64String(aBase64);
			return JSONNode.LoadFromStream(new MemoryStream(buffer)
			{
				Position = 0L
			});
		}
	}
}
